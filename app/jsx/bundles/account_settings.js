require [
  'react',
  'react-dom',
  'compiled/views/feature_flags/FeatureFlagAdminView',
  'jsx/custom_help_link_settings/CustomHelpLinkSettings',
  'account_settings',
  'compiled/bundles/modules/account_quota_settings'
], (React, ReactDOM, FeatureFlagAdminView, CustomHelpLinkSettings) ->
  featureFlags = new FeatureFlagAdminView(el: '#tab-features')
  featureFlags.collection.fetchAll()

  if document.getElementById('custom_help_link_settings')
    ReactDOM.render(React.createElement(CustomHelpLinkSettings, {
        name: window.ENV.help_link_name,
        icon: window.ENV.help_link_icon,
        links: window.ENV.CUSTOM_HELP_LINKS,
        defaultLinks: window.ENV.DEFAULT_HELP_LINKS
      }), document.getElementById('custom_help_link_settings'))
