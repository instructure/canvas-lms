# i18n friendly ActiveSupport::TimeZone subclass extended to play nicely with
# our #time_zone_options_for_select method on ActionView::Helpers::InstanceTag
class I18nTimeZone < ActiveSupport::TimeZone
  @lazy_zones_map = ThreadSafe::Cache.new unless CANVAS_RAILS4_0 # this initialization doesn't get inherited, apparently

  def to_s
    translated_name = I18n.send(:translate, keyify) || name
    "#{translated_name} (#{formatted_offset})"
  end

  def keyify
    "time_zones.#{name.gsub(/(\W|\s)/,'').underscore}"
  end
end
