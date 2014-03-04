require 'statsd'

module CanvasStatsd
  require "canvas_statsd/statsd"

  def self.settings
    @settings || {}
  end

  def self.settings=(value)
    @settings = value
  end
end
