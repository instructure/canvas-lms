# override time_zone_options_for_select so the name comes before the offset
# (only change is to the convert_zones lambda). TODO: I18n the names
ActionView::Helpers::InstanceTag.class_eval do
  def time_zone_options_for_select(selected = nil, priority_zones = nil, model = ::ActiveSupport::TimeZone)
    zone_options = ""
    selected = selected.name if selected && selected.is_a?(::ActiveSupport::TimeZone)

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

ActionController::DataStreaming.class_eval do
  def send_file_with_content_length(path, options = {})
    headers.merge!('Content-Length' => File.size(path).to_s)
    send_file_without_content_length(path, options)
  end
  alias_method_chain :send_file, :content_length

  def send_data_with_content_length(data, options = {})
    headers.merge!('Content-Length' => data.length.to_s) if data.respond_to?(:length)
    send_data_without_content_length(data, options)
  end
  alias_method_chain :send_data, :content_length
end
