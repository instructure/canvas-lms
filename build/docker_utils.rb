# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require "yaml"

class DockerUtils
  class << self
    def compose_config(*compose_files)
      merger = proc do |_, v1, v2|
        if Hash === v1 && Hash === v2
          v1.merge(v2, &merger)
        elsif Array === v1 && Array === v2
          v1.concat(v2)
        else
          v2
        end
      end

      compose_files.inject({}) do |config, file|
        config.merge(YAML.load_file(file), &merger)
      end
    end
  end
end
