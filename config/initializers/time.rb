Time.class_eval do
  def utc_datetime
    timestamp = self.getutc
    DateTime.civil(timestamp.strftime("%Y").to_i, 
                   timestamp.strftime("%m").to_i,
                   timestamp.strftime("%d").to_i,
                   timestamp.strftime("%H").to_i, 
                   timestamp.strftime("%M").to_i)
  end
end

# Object#blank? calls respond_to?, which has to instantiate the time object
# by doing an expensive time zone calculation.  So just skip that.
class ActiveSupport::TimeWithZone
  def blank?
    false
  end

  def utc_datetime
    self.comparable_time.utc_datetime
  end
end
