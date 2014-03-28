module CanvasTime
  # set to 11:59pm if it's 12:00am
  def self.fancy_midnight(time)
    return time if time.nil? || time.hour != 0 || time.min != 0
    time.end_of_day
  end

  def self.is_fancy_midnight?(time)
    return false unless time
    time.hour == 23 && time.min == 59
  end

  def self.try_parse(maybe_time, default=nil)
    begin
      Time.zone.parse(maybe_time) || default
    rescue
      default
    end
  end
end