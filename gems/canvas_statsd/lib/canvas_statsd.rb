require 'statsd'

module CanvasStatsd
  require "canvas_statsd/statsd"
  require "canvas_statsd/request_stat"

  def self.settings
    @settings || {}
  end

  def self.settings=(value)
    @settings = value
  end
end
