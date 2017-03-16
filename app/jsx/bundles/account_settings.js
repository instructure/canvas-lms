import React from 'react'
import ReactDOM from 'react-dom'
import FeatureFlagAdminView from 'compiled/views/feature_flags/FeatureFlagAdminView'
import CustomHelpLinkSettings from 'jsx/custom_help_link_settings/CustomHelpLinkSettings'
import 'account_settings'
import 'compiled/bundles/modules/account_quota_settings'

const featureFlags = new FeatureFlagAdminView({el: '#tab-features'})
featureFlags.collection.fetchAll()

if (document.getElementById('custom_help_link_settings')) {
  ReactDOM.render(
    <CustomHelpLinkSettings
      {...{
        name: window.ENV.help_link_name,
        icon: window.ENV.help_link_icon,
        links: window.ENV.CUSTOM_HELP_LINKS,
        defaultLinks: window.ENV.DEFAULT_HELP_LINKS
      }}
    />,
    document.getElementById('custom_help_link_settings')
  )
}

