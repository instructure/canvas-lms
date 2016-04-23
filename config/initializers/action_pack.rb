module TimeZoneFormImprovements
  def time_zone_options_for_select(selected = nil, priority_zones = nil, model = I18nTimeZone)
    selected = selected.name if selected && selected.is_a?(ActiveSupport::TimeZone)
    result = super(selected, priority_zones, model)

    # the current value isn't one of Rails' friendly zones; just add it to the top
    # of the list literally
    if selected && !ActiveSupport::TimeZone.all.map(&:name).include?(selected)
      zone = ActiveSupport::TimeZone[selected]
      return result unless zone

      unfriendly_zone = "".html_safe
      unfriendly_zone.safe_concat options_for_select([["#{selected} (#{zone.formatted_offset})", selected]], selected)
      unfriendly_zone.safe_concat content_tag("option".freeze, '-------------', value: '', disabled: true)
      unfriendly_zone.safe_concat "\n"
      unfriendly_zone.safe_concat result
      result = unfriendly_zone
    end

    result
  end
end

ActionView::Helpers::FormOptionsHelper.prepend(TimeZoneFormImprovements)

ActionController::DataStreaming.class_eval do
  def send_file_with_content_length(path, options = {})
    headers.merge!('Content-Length' => File.size(path).to_s)
    send_file_without_content_length(path, options)
  end
  alias_method_chain :send_file, :content_length

  def send_data_with_content_length(data, options = {})
    headers.merge!('Content-Length' => data.bytesize.to_s) if data.respond_to?(:bytesize)
    send_data_without_content_length(data, options)
  end
  alias_method_chain :send_data, :content_length
end
