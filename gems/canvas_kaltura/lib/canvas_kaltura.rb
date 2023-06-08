# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "canvas_http"
require "canvas_sort"

module CanvasKaltura
  require "canvas_kaltura/kaltura_client_v3"
  require "canvas_kaltura/kaltura_string_io"

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger
  end

  def self.error_handler=(error_handler)
    @error_handler = error_handler
  end

  def self.error_handler
    @error_handler
  end

  def self.cache=(cache)
    @cache = cache
  end

  def self.cache
    return @cache.call if @cache.is_a?(Proc)

    @cache
  end

  def self.with_timeout_protector(options = {}, &)
    return yield unless @timeout_protector_proc

    @timeout_protector_proc.call(options, &)
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
