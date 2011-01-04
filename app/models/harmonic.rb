class Harmonic
  # Harmonic constants should be expressed in hours
  def initialize(amp, speed, phase)
    @amp = amp 
    @speed = d_to_r(speed)
    @phase = d_to_r(phase)
  end
  
  def contribution(t)
    # time in hours
    @amp * Math.cos(@speed * t - @phase)
  end
  
  private 
  def d_to_r(deg)
    deg * Math::PI / 180.0
  end
end