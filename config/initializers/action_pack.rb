# override time_zone_options_for_select so the name comes before the offset
# (only change is to the convert_zones lambda). TODO: I18n the names
ActionView::Helpers::InstanceTag.class_eval do
  def time_zone_options_for_select(selected = nil, priority_zones = nil, model = ::ActiveSupport::TimeZone)
    zone_options = ""

    zones = model.all
    convert_zones = lambda { |list| list.map { |z| [ "#{z.name} (#{z.formatted_offset})", z.name ] } }

    if priority_zones
      if priority_zones.is_a?(Regexp)
        priority_zones = model.all.find_all {|z| z =~ priority_zones}
      end
      zone_options += options_for_select(convert_zones[priority_zones], selected)
      zone_options += "<option value=\"\" disabled=\"disabled\">-------------</option>\n"

      zones = zones.reject { |z| priority_zones.include?( z ) }
    end

    zone_options += options_for_select(convert_zones[zones], selected)
    zone_options.html_safe
  end
end
