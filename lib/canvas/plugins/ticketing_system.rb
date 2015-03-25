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
      def is_selected?(plugin_id, setting_registry = PluginSetting)
        setting = setting_registry.settings_for_plugin(PLUGIN_ID)
        return false if setting.nil?
        plugin_id.to_s == setting[:type].to_s
      end

    end
  end
end
