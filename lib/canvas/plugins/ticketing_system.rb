# Plugin and module for Bring Your Own Ticketing System
#
# The idea is that other connectors for specific ticketing systems
#  (zendesk, servicecloud, etc) could be registersed
#  as another plugin with "byots" as their tag and use the settings
#  from this one to decide which ticketing system to use per account.
#
module Canvas::Plugins
  module TicketingSystem

    # can use this constant as the "tag" for other connectors
    PLUGIN_ID = 'ticketing_system'

    class << self

      # public, but not for you to use.  this method wraps the registration
      # that "default_plugins.rb" does, so since there's a little behavior
      # this plugin needs anyway, may as well let it manage it's own
      # registration
      def register!
        Canvas::Plugin.register(PLUGIN_ID, nil, {
          name: ->{ I18n.t 'Ticketing System' },
          description: ->{ I18n.t 'Ticketing system configurations' },
          author: 'Instructure',
          author_website: 'http://www.instructure.com',
          version: '1.0.0',
          settings_partial: 'plugins/ticketing_system_settings',
          validator: 'TicketingSystemValidator'
        })
        TicketingSystem::EmailPlugin.new(self).register!
        TicketingSystem::WebPostPlugin.new(self).register!
      end

      # any child plugin can use this method to register itself
      # without having to know about Canvas's plugin architecture,
      # or the tag it needs to use, or the way to register a callback
      # with error_report.rb
      #
      # Params:
      #   plugin_id -> String, some unique string identifier for this plugin
      #   options -> Hash, a settings hash similar to the one this plugin uses
      #     above in ".register!"
      #   callback -> Block<ErrorReport>, the thing that should run everytime
      #     an error report is created in Canvas
      def register_plugin(plugin_id, options, &callback)
        Canvas::Plugin.register(plugin_id, PLUGIN_ID, options)
        ::ErrorReport.set_callback(:on_send_to_external) do |report|
          callback.call(report)
        end
      end

      # grabs the settings for a given plugin ID from the plugins
      # module, but gives some nil protection with a default empty hash
      #
      # returns Hash
      def get_settings(plugin_id)
        Canvas::Plugin.find(plugin_id).try(:settings) || {}
      end

      # provided for each connector to check and see if they're the contextually
      # selected plugin to use.  For example, if there were a connector to
      # the MeerkatSupport ticekting service, it would have registered itself
      # as the "meerkat_support" plugin with "byots" as it's tag,
      # and when checking to see if it needed
      # to execute its behavior for a given callback, it might check:
      #
      # Canvas::TicketingSystem.is_selected?("meerkat_support")
      #
      # to see if it was enabled (that is, selected as the BYOTS connector
      # for this given account).
      #
      # returns true/false
      def is_selected?(plugin_id, setting_registry = PluginSetting)
        setting = setting_registry.settings_for_plugin(PLUGIN_ID)
        return false if setting.nil?
        plugin_id.to_s == setting[:type].to_s
      end

      # Helper that returns other plugins that have been registered
      # with this tag, useful for generating a list of these (in the
      #  select box for picking which plugin to use in the settings
      #  area, for example) without just having to repeat this id
      #  everywhere
      #
      #  returns Array<Canvas::Plugin>
      def registered_extensions
        Canvas::Plugin.all_for_tag(PLUGIN_ID)
      end

    end
  end
end
