#
# Copyright (C) 2014 Instructure, Inc.
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

module EventStream::AttrConfig
  module ClassMethods
    CASTS = {
        String => lambda { |name, value| value.to_s },
        Integer => lambda { |name, value| value.to_i },
        Proc => lambda { |name, value|
          return value if value.nil? || value.respond_to?(:call)
          raise(ArgumentError, "Expected attribute #{name} to be a Proc: #{value.class}")
        }
    }

    def attr_config_defaults
      @attr_config_defaults ||= {}
    end

    def attr_config_known
      @attr_config_known ||= Set.new
    end

    def attr_config(name, options={})
      attr_config_known << name
      if options.has_key?(:type)
        type = options[:type]
        typecast = CASTS[type]
      end
      required = !options.has_key?(:default)
      unless required
        default = options[:default]
        default = typecast.call(name, default) if default && typecast
        attr_config_defaults[name] = default
      end

      define_method(name) do |*args|
        raise ArgumentError if args.length > 1

        if args.empty?
          value = attr_config_values[name]
          if type != Proc && value.respond_to?(:call)
            value = value.call
            if required && value.nil?
              raise ArgumentError, "Proc attribute #{name} returned nil when #{name} is required."
            end

            return typecast.call(name, value) if typecast
            return value
          end
          return value
        end

        value = args.first
        if typecast && !value.respond_to?(:call)
          value = typecast.call(name, value)
        end
        attr_config_values[name] = value
      end
    end
  end

  def attr_config_values
    @attr_config_values ||= {}
  end

  def attr_config_validate
    self.class.attr_config_defaults.each do |key, value|
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
