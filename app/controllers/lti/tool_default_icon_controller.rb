# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Lti
  class ToolDefaultIconController < ApplicationController
    # Generates an SVG icon for a tool based on its name and ID

    # NOTE! If we ever change this file or the template, we'll need to
    # bust users' caches by changing the route in routes.rb or adding a
    # "version" parameter or similar to the URL. See
    # ContextExternalTool#default_icon_path for usage
    CACHE_MAX_AGE = 1.month.seconds

    COLORS = %w[#fb5607 #3a86ff #5f9207 #8338ec #d81159 #390099 #9e0059].freeze

    def show
      # Use first number/"letter-like" character ('0', 'a', 'é', '我', etc.), or none.
      @glyph = params[:name]&.match(/[0-9\p{Letter}]/)&.to_s&.upcase
      # Color based on hash of the developer key / tool (global) ID.
      @color = COLORS[params[:id].hash % COLORS.length]

      response.headers["Cache-Control"] = "max-age=#{CACHE_MAX_AGE}"
      cancel_cache_buster

      render content_type: "image/svg+xml", layout: false
    end
  end
end
