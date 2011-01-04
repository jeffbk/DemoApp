class TidesController < ApplicationController
  PREDICTION_LENGTH = 1440 # minutes
  PREDICTION_STEP = 6 # minutes
  def predict
    now = Time.now.getutc
    # round time to nearest hour
    time = Time.utc(now.year, now.month, now.day, now.hour) 
    tp = TidePredictor.new
    prediction = tp.predict(params[:id], time, PREDICTION_LENGTH, PREDICTION_STEP)
    # data to pass to graph
    @xaxis_ticks = []
    @datapoints = []
    @ymax = 0
    @ymin = 0
    
    tickstep = PREDICTION_LENGTH / PREDICTION_STEP  / 4
    prediction.datapoints.length.times do |i|
      @datapoints << [i, prediction.datapoints[i].height]
      if i % (tickstep) == 0 then
        @xaxis_ticks << [i, Time.at(prediction.datapoints[i].time.to_i)]
      end
      if prediction.datapoints[i].height > @ymax then @ymax = prediction.datapoints[i].height end
      if prediction.datapoints[i].height < @ymin then @ymin = prediction.datapoints[i].height end
    end           
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => prediction }
    end
  end
end
