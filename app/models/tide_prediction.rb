class TidePrediction

  def initialize(station_id, time)
    @time = time
    @station_id = station_id
    @datapoints = []
  end
  
  attr_accessor :time, :station_id, :datapoints
end