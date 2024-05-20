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

module CanvasCrummy
  module ControllerMethods
    module ClassMethods
      # Add a crumb to the crumbs array.
      #
      #   add_crumb("Home", "/")
      #   add_crumb("Business") { |instance| instance.business_path }
      #
      # Works like a before_filter so +:only+ and +except+ both work.
      def add_crumb(name, *args)
        options = args.extract_options!
        url = args.first
        # I wanted this next line to look more like:
        # html_options = options.pluck { |k,v| %w{class id}.include? k.to_s  }
        # but couldn't figure out how
        html_options = options[:class] ? { class: options[:class] } : {}
        html_options[:id] = options[:id] if options[:id]
        raise ArgumentError, "Need more arguments" unless name || options[:record] || block_given?
        raise ArgumentError, "Cannot pass url and use block" if url && block_given?

        before_action(options) do |instance|
          url_value = url
          url_value = yield instance if block_given?
          url_value = instance.send url_value if url_value.is_a? Symbol
          name_value = name
          name_value = instance.instance_eval(&name_value) if name_value.is_a? Proc
          name_value = instance.instance_variable_get(:"@#{name_value}") if name_value.is_a? Symbol
          record = instance.instance_variable_get(:"@#{name_value}") unless url_value || block_given?
          if record
            name_value, url_value = record.to_s, instance.url_for(record)
          end

          # FIXME: url_value = instance.url_for(name_value) if name_value.respond_to?("to_param") && url_value.nil?
          # FIXME: Add ||= for the name_value, url_value above
          instance.add_crumb(name_value, url_value, html_options)
        end
      end
    end

    module InstanceMethods
      # Add a crumb to the crumbs array.
      #
      #   add_crumb("Home", "/")
      #   add_crumb("Business") { |instance| instance.business_path }
      #
      def add_crumb(name, url = nil, options = {})
        crumbs.push [name, url, options]
      end

      def clear_crumbs
        crumbs.clear
      end

      # Lists the crumbs as an array
      def crumbs
        get_or_set_ivar "@_crumbs", []
      end

      def get_or_set_ivar(var, value) # :nodoc:
        instance_variable_set var, instance_variable_get(var) || value
      end

      private :get_or_set_ivar
    end

    def self.included(receiver) # :nodoc:
      receiver.extend ClassMethods
      receiver.include InstanceMethods
    end
  end
end
