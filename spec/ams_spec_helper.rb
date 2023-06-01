# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
#

require "active_model_serializers"
require "action_controller"
require "active_record"

# You can include just this file if your serializer doesn't need too much
# from the whole stack to run your tests faster!

module ActiveModel
  class FakeController
    include Rails.application.routes.url_helpers
    def default_url_options
      { host: "example.com" }
    end

    attr_accessor :accepts_jsonapi, :stringify_json_ids, :session, :context

    def initialize(options = {})
      @accepts_jsonapi = options.fetch(:accepts_jsonapi, true)
      @stringify_json_ids = options.fetch(:stringify_json_ids, true)
      @session = options[:session]
      @context = options[:context]
    end

    def accepts_jsonapi?
      !!accepts_jsonapi
    end

    def stringify_json_ids?
      !!stringify_json_ids
    end
  end
end

require_relative "../app/serializers/canvas/api_serialization"
require_relative "../app/serializers/canvas/api_serializer"
require_relative "../app/serializers/canvas/api_array_serializer"

Dir[File.expand_path(File.dirname(__FILE__) + "/../app/serializers/*.rb")].each do |file|
  require file
end
