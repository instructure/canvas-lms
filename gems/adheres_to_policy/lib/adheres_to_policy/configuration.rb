# frozen_string_literal: true

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
#
module AdheresToPolicy
  class Configuration
    @defaults = {}

    class << self
      attr_reader :defaults

      def attr_accessor_with_default(attr_name, default_value)
        attr_writer attr_name

        @defaults[attr_name] = default_value

        define_method attr_name do
          value = instance_variable_get(:"@#{attr_name}")
          value.respond_to?(:call) ? value.call : value
        end
      end
    end

    attr_accessor_with_default :blacklist, []
    attr_accessor_with_default :cache_related_permissions, true
    attr_accessor_with_default :cache_intermediate_permissions, true
    attr_accessor_with_default :cache_permissions, true

    def initialize
      init_defaults
    end

    def reset!
      init_defaults
    end

    private

    def init_defaults
      self.class.defaults.each do |attr_name, default_value|
        instance_variable_set(:"@#{attr_name}", default_value)
      end
    end
  end
end
