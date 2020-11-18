# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Canvas::Plugins::TicketingSystem

  # This isn't a class intended to be used on it's own.  It's an abstract
  # base class for all ticketing system connectors to inherit from.
  #
  # Typical usage would involve extending it, defining 3 template methods
  # (plugin_id, settings, and export_error), and at runtime wrapping it
  # around the TicketingSystem class object (although another could
  # be provided if the same interface were adhered to).
  #
  # NewPlugin.new(Canvas::Plugins::TicketingSystem).register!
  #
  # if everything is defined correctly, then every time an ErrorReport
  # is created, your "export_error" method will be called with the
  # error report (wrapped in a Canvas:Plugins::TicketingSystem::CustomError)
  class BasePlugin
    attr_reader :ticketing_system

    def initialize(ticketing_system)
      @ticketing_system = ticketing_system
    end

    def register!
      ticketing_system.register_plugin(plugin_id, settings) do |report|
        export_error(CustomError.new(report), config) if enabled?
      end
    end

    def config
      ticketing_system.get_settings(plugin_id)
    end

    def enabled?
      ticketing_system.is_selected?(plugin_id) && !config.empty?
    end

    # Whatever you want to do when an ErrorReport is created (notify
    # an external ticket tracker, log some stats, etc) do it inside
    # this method when you override it.  The one parameter it
    # recieves is a Canvas ErrorReport decorated with
    # a CustomError from this same module (Canvas::Plugins::TicketingSystem).
    def export_error(report, conf)
      raise "MUST OVERRIDE WITH THE CALLBACK FOR ERROR REPORT"
    end

    # When overriding, this should just provide the String which is
    # the unique name of this plugin to use in the canvas plugin registry
    def plugin_id
      raise "MUST OVERRIDE WITH THE PLUGIN ID TO REGISTER WITH"
    end

    # When overriding, this method should return a hash very similar to
    # all the hashes found for plugin registration in
    # lib/canvas/plugins/default_plugins.rb
    def settings
      raise "MUST OVERRIDE WITH A SETTINGS HASH FOR PLUGIN REGISTRATION"
    end
  end

end
