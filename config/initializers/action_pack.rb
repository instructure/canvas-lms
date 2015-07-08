ActionView::Helpers::InstanceTag.class_eval do
  def time_zone_options_for_select(selected = nil, priority_zones = nil, model = I18nTimeZone)
    selected = selected.name if selected && selected.is_a?(::ActiveSupport::TimeZone)
    super(selected, priority_zones, model)
  end
end

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
