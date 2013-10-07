Time.class_eval do
  def utc_datetime
    timestamp = self.getutc
    DateTime.civil(timestamp.strftime("%Y").to_i, 
                   timestamp.strftime("%m").to_i,
                   timestamp.strftime("%d").to_i,
                   timestamp.strftime("%H").to_i, 
                   timestamp.strftime("%M").to_i)
  end

  def as_json_with_utc(options={})
    self.utc.as_json_without_utc(options)
  end
  alias_method_chain :as_json, :utc
end

DateTime.class_eval do
  def as_json_with_utc(options={})
    self.utc.as_json_without_utc(options)
  end
  alias_method_chain :as_json, :utc
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

  def as_json(options={})
    self.utc.as_json_without_utc(options)
  end
end
