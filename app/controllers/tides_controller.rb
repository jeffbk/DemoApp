class Numeric
  def d_to_r
    self * Math::PI / 180 
  end
end

class TideLevelDatum
  attr_accessor :dt, :height
  def intialize(dt, height)
    @dt = dt
    @height = height
  end
end

class TidePrediction
  attr_accessor :dt, :station_id, :datapoints
  def initialize(dt, station_id)
    @dt = dt
    @station_id = station_id
    @datapoints = []
    @highs = []
    @lows = []
  end
end
    
class Harmonic
  def initialize(amp, speed, phase, nodefactor, equilibrium)
    @amp = amp * nodefactor
    @speed = speed
    @phase = phase - equilibrium
  end
  
  def contribution(t)
    # time in hours
    @amp * Math.cos((@speed * t / 60.0 - @phase).d_to_r)
  end
end

class TidePredictor
  DB_PATH = 'config/harmdb'
  HARMONIC_DATA_SELECT = 'SELECT constituents.name, constituents.speed, constants.amp,
                constants.phase, mod.node_factor, mod.equilibrium FROM data_sets d
                JOIN constants ON constants.id = d.id
                JOIN constituents ON constituents.name = constants.name
                JOIN modulations mod ON mod.name = constants.name
                WHERE d.id = ? AND mod.year = ?'
  PREDICTION_LENGTH = 1440 # minutes
  PREDICTION_STEP = 6 # minutes
  def predict(station_id, dt)
    tzero = Time.utc(dt.year, 1, 1, 0, 0)
    tstart = (dt.to_i - tyear.to_i) / 60  # time in minutes
    tend = tstart + PREDICTION_LENGTH
    prediction = TidePrediction.new(dt, station_id, station_name)
    harmonics = get_harmonics(station_id, dt.year)
    (tstart..tend).step(PREDICTION_STEP) do |t|
      height = 0 
      harmonics.each do |harmonic|
        height = height + harmonic.contribution(t / 60.0) # time in hours
      end
      prediction.datapoints << TideLevelDatum.new(Time.utc(tzero.to_i + t * 60), height)
    end
    return prediction
  end  
  
  
  def get_harmonics(id, year)
    db = SQLite3::Database.new(DB_PATH)
    rows = db.execute(HARMONIC_DATA_SELECT, station_id, year)
    db.close()    
    harmonics = []
    rows.each do |row|
      speed = Float(row[1])
      amp = Float(row[2])
      nf = Float(row[4])
      phase = Float(row[3])
      eq = Float(row[5]) 
      harmonics << Harmonic.new(amp, speed, phase, nf, eq)
    end
    harmonics
  end
end
  

class TidesController < ApplicationController
  def predict
    tnow = Time.new()
    year = Time.new().year
    year = year + 1 if tnow.month > 6
    db = SQLite3::Database.new('config/harmdb')
    # get harmonic data
    rows = db.execute('SELECT constituents.name, constituents.speed, constants.amp,
                  constants.phase, mod.node_factor, mod.equilibrium FROM data_sets d
                  JOIN constants ON constants.id = d.id
                  JOIN constituents ON constituents.name = constants.name
                  JOIN modulations mod ON mod.name = constants.name
                  WHERE d.id = ? AND mod.year = ?', params[:id], year)
    # get station name
    @station_name = db.execute('SELECT name from data_sets WHERE id = ?', params[:id])
    db.close()
    tsec = tnow.to_i / 900 * 900 # truncate to nearest quarter hour
    t = (tsec - Time.utc(year, 1, 1, 0, 0).to_i) / 60.0  
    minutes = 1440
    @datapoints = []
    @ticks = []
    @ymax = 0
    @ymin = 0
    (0..minutes).step(6) do |i|
      height = 0 
      rows.each do |row|
        speed = Float(row[1])
        amp = Float(row[2])
        nf = Float(row[4])
        phase = Float(row[3])
        eq = Float(row[5]) 
        h = amp * nf * Math.cos((speed * ((t + i) / 60.0) + eq - phase).d_to_r)
        height = height + h
      end
      @datapoints << [i, height]
      if i % 480 == 0 then
        @ticks << [i, Time.at(tsec + i * 60)]
      end
      if height > @ymax then @ymax = height end
      if height < @ymin then @ymin = height end
    end           
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end
  end
end
