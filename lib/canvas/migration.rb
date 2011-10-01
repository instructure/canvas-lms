require 'json'
require 'time'
require 'set'
require 'zip/zip'
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
end

require_dependency 'canvas/migration/migrator'
require_dependency 'canvas/migration/migrator_helper'
require_dependency 'canvas/migration/worker'
require_dependency 'canvas/migration/xml_helper'