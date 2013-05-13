#
# Copyright (C) 2013 Instructure, Inc.
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

module AttrConfig
  module ClassMethods
    CASTS = {
      String => lambda{ |value| value.to_s },
      Fixnum => lambda{ |value| value.to_i },
    }

    def attr_config_defaults
      @attr_config_defaults ||= {}
    end

    def attr_config_known
      @attr_config_known ||= Set.new
    end

    def attr_config(name, options={})
      attr_config_known << name
      typecast = CASTS[options[:type]]

      if options.has_key?(:default)
        default = options[:default]
        default = typecast.call(default) if default && typecast
        attr_config_defaults[name] = default
      end

      if typecast
        define_method(name) do |*args|
          raise ArgumentError if args.length > 1
          return attr_config_values[name] if args.empty?
          attr_config_values[name] = typecast.call(args.first)
        end
      else
        define_method(name) do |*args|
          raise ArgumentError if args.length > 1
          return attr_config_values[name] if args.empty?
          attr_config_values[name] = args.first
        end
      end
    end
  end

  def attr_config_values
    @attr_config_values ||= {}
  end

  def attr_config_validate
    self.class.attr_config_defaults.each do |key,value|
      unless attr_config_values.has_key?(key)
        attr_config_values[key] = value
      end
    end
    missing = self.class.attr_config_known - attr_config_values.keys
    raise ArgumentError, "missing required attributes: #{missing.to_a}" unless missing.empty?
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
