# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "canvas/cdn"

module Canvas
  module Cdn
    module RevvedAssetUrls
      def path_to_asset(source, options = {})
        original_path = super
        revved_url = ::Canvas::Cdn.registry.url_for(original_path)
        if revved_url
          File.join(compute_asset_host(revved_url, options).to_s, revved_url)
        else
          original_path
        end
      end
    end
  end
end
