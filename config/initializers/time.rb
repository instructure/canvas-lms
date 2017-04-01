module JsonTimeInUTC
  def as_json(options = {})
    return super if utc?
    utc.as_json(options)
  end
end
Time.prepend(JsonTimeInUTC)
DateTime.prepend(JsonTimeInUTC)
ActiveSupport::TimeWithZone.prepend(JsonTimeInUTC)

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

module TimeZoneAsJson
  def as_json(_options = {})
    tzinfo.name
  end
end

ActiveSupport::TimeZone.include(TimeZoneAsJson)

# Add Paraguay (Asuncion) as a friendly time zone
ActiveSupport::TimeZone::MAPPING['Asuncion'] = 'America/Asuncion'
ActiveSupport::TimeZone.instance_variable_set(:@zones, nil)
ActiveSupport::TimeZone.instance_variable_set(:@zones_map, nil)
if CANVAS_RAILS4_2
  ActiveSupport::TimeZone.instance_variable_set(:@lazy_zones_map, ThreadSafe::Cache.new)
else
  ActiveSupport::TimeZone.instance_variable_set(:@lazy_zones_map, Concurrent::Map.new)
  ActiveSupport::TimeZone.instance_variable_set(:@country_zones, Concurrent::Map.new)
end
