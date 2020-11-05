# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
