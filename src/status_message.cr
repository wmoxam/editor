class StatusMessage
  property message : String
  property time : Time

  def initialize(message = "")
    @message = message
    @time = Time.local
  end

  def set(message)
    @message = message
    @time = Time.local
  end

  def visible?
    (Time.local - time).seconds < 5
  end
end
