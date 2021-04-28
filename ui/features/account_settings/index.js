/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import ReactDOM from 'react-dom'
import I18n from 'i18n!account_settings_jsx_bundle'
import FeatureFlagAdminView from '@canvas/feature-flag-admin-view'
import CustomHelpLinkSettings from './react/custom_help_link_settings/CustomHelpLinkSettings'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import './jquery/index'
import './backbone/account_quota_settings.coffee'
import FeatureFlags from '@canvas/feature-flags'
import ready from '@instructure/ready'

ready(() => {
  if (window.ENV.NEW_FEATURES_UI) {
    ReactDOM.render(<FeatureFlags />, document.getElementById('tab-features'))
  } else {
    const featureFlags = new FeatureFlagAdminView({el: '#tab-features'})
    featureFlags.collection.fetchAll()
  }

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

  if (document.getElementById('tab-security')) {
    ReactDOM.render(
      <View as="div" margin="large" padding="large" textAlign="center">
        <Spinner size="large" renderTitle={I18n.t('Loading')} />
      </View>,
      document.getElementById('tab-security')
    )
  }
})
