class TidePredictor
  
  DB_FILE = 'config/harmdb'
  HARMONIC_DATA_SELECT = 'SELECT constituents.name, constituents.speed, constants.amp,
                constants.phase, mod.node_factor, mod.equilibrium FROM data_sets d
                JOIN constants ON constants.id = d.id
                JOIN constituents ON constituents.name = constants.name
                JOIN modulations mod ON mod.name = constants.name
                WHERE d.id = ? AND mod.year = ?'

  def predict(station_id, time, length, step)
    tzero = Time.utc(time.year, 1, 1, 0, 0)
    startseconds = time.to_i - tzero.to_i 
    length = length * 60 # convert to seconds
    step = step * 60 # convert to seconds
    endseconds = startseconds + length
    prediction = TidePrediction.new(station_id, time)
    harmonics = get_harmonics(station_id, time.year)
    (startseconds..endseconds).step(step) do |t|
      height = 0 
      harmonics.each do |harmonic|
        height = height + harmonic.contribution(t / 3600.0) # time in hours
      end
      prediction.datapoints << TideDatum.new(tzero + t, height)
    end
    return prediction
  end  
  
  def get_harmonics(id, year)
    db = SQLite3::Database.new(DB_FILE)
    rows = db.execute(HARMONIC_DATA_SELECT, id, year)
    db.close()    
    harmonics = []
    rows.each do |row|
      speed = Float(row[1])
      amp = Float(row[2])
      nf = Float(row[4])
      phase = Float(row[3])
      eq = Float(row[5]) 
      harmonics << Harmonic.new(amp * nf, speed, phase - eq)
    end
    harmonics
  end
end