require 'json'
require 'time'
require 'set'
require 'zip'
require 'net/http'
require 'uri'
require 'cgi'
require 'nokogiri'

module Canvas::Migration
  def self.logger
    Rails.logger
  end
  def logger
    Rails.logger
  end

  def self.valid_converter_classes
    @converter_classes ||= Canvas::Plugin.all_for_tag(:export_system).map {|p| p.meta["settings"]["provides"].try(:values) }.flatten.compact.uniq.map(&:name)
  end
end

require_dependency 'canvas/migration/migrator'
require_dependency 'canvas/migration/migrator_helper'
require_dependency 'canvas/migration/worker'
require_dependency 'canvas/migration/xml_helper'
