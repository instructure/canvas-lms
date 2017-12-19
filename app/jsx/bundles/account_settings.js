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
import FeatureFlagAdminView from 'compiled/views/feature_flags/FeatureFlagAdminView'
import CustomHelpLinkSettings from '../custom_help_link_settings/CustomHelpLinkSettings'
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

