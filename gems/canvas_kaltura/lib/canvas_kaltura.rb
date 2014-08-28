require 'canvas_http'
require 'canvas_sort'

module CanvasKaltura
  require "canvas_kaltura/kaltura_client_v3"
  require "canvas_kaltura/kaltura_string_io"

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger
  end

  def self.cache=(cache)
    @cache = cache
  end

  def self.cache
    @cache
  end

  def self.with_timeout_protector(options = {}, &block)
    @timeout_protector_proc ||= Proc.new do
      block.call
    end
    @timeout_protector_proc.call(options, &block)
  end

  def self.timeout_protector_proc=(callable)
    @timeout_protector_proc = callable
  end

  def self.plugin_settings=(kaltura_settings)
    @plugin_settings = kaltura_settings
  end

  def self.plugin_settings
    @plugin_settings.call
  end
end
