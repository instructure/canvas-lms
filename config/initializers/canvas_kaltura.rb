Rails.configuration.to_prepare do
  CanvasKaltura.timeout_protector_proc = Proc.new() do |options, &block|
    Canvas.timeout_protection("kaltura", options, &block)
  end
  CanvasKaltura.logger = Rails.logger
  CanvasKaltura.cache = Rails.cache
  CanvasKaltura.plugin_settings = -> { Canvas::Plugin.find(:kaltura) }
end