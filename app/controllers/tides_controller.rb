class Numeric
  def d_to_r
    self * Math::PI / 180 
  end
end


class TidesController < ApplicationController
  def predict
    db = SQLite3::Database.new('config/harmdb')
    rows = db.execute('SELECT constituents.name, constituents.speed, constants.amp,
                  constants.phase, mod.node_factor, mod.equilibrium FROM data_sets d
                  JOIN constants ON constants.id = d.id
                  JOIN constituents ON constituents.name = constants.name
                  JOIN modulations mod ON mod.name = constants.name
                  WHERE d.id = ? AND mod.year = ?', params[:id], 2011)
    @station_name = db.execute('SELECT name from data_sets WHERE id = ?', params[:id])
    db.close()
    tnow = Time.new()
    tbase = Time.utc(2011, 1, 1, 0, 0)
    t = (tnow.to_i - tbase.to_i) / 60.0
    @minutes = 2880
    @heights = []
    @ticks = []
    @test
    (0..@minutes).step(6) do |i|
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
      @heights << [i, height]
      if i % 480 == 0 then
        @ticks << [i, Time.at(tnow.to_i + i * 60).strftime('%m-%d %H:%M %Z')]
      end
    end
    @test = '"hello"'            
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end
  end

end
