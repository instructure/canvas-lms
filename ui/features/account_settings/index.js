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
import {useScope as useI18nScope} from '@canvas/i18n'
import CustomEmojiDenyList from './react/custom_emoji_deny_list/CustomEmojiDenyList'
import CustomHelpLinkSettings from './react/custom_help_link_settings/CustomHelpLinkSettings'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import './jquery/index'
import './backbone/account_quota_settings'
import FeatureFlags from '@canvas/feature-flags'
import ready from '@instructure/ready'
import MicrosoftSyncAccountSettings from '@canvas/integrations/react/accounts/microsoft_sync/MicrosoftSyncAccountSettings'
import CourseCreationSettings from './react/course_creation_settings/CourseCreationSettings'
import {InternalSettings} from './react/internal_settings/InternalSettings'

const I18n = useI18nScope('account_settings_jsx_bundle')

ready(() => {
  ReactDOM.render(<FeatureFlags />, document.getElementById('tab-features'))

  if (document.getElementById('custom_help_link_settings')) {
    ReactDOM.render(
      <CustomHelpLinkSettings
        {...{
          name: window.ENV.help_link_name,
          icon: window.ENV.help_link_icon,
          links: window.ENV.CUSTOM_HELP_LINKS,
          defaultLinks: window.ENV.DEFAULT_HELP_LINKS,
        }}
      />,
      document.getElementById('custom_help_link_settings')
    )
  }

  const emojiDenyListContainer = document.getElementById('emoji-deny-list')
  if (emojiDenyListContainer) {
    ReactDOM.render(<CustomEmojiDenyList />, emojiDenyListContainer)
  }

  if (document.getElementById('tab-security')) {
    ReactDOM.render(
      <View as="div" margin="large" padding="large" textAlign="center">
        <Spinner size="large" renderTitle={I18n.t('Loading')} />
      </View>,
      document.getElementById('tab-security')
    )
  }

  const internalSettingsMountpoint = document.getElementById('tab-internal-settings')
  if (internalSettingsMountpoint) {
    ReactDOM.render(<InternalSettings />, internalSettingsMountpoint)
  }

  if (document.getElementById('tab-integrations')) {
    ReactDOM.render(<MicrosoftSyncAccountSettings />, document.getElementById('tab-integrations'))
  }

  const courseCreationSettingsContainer = document.getElementById('course_creation_settings')
  if (courseCreationSettingsContainer) {
    ReactDOM.render(
      <CourseCreationSettings currentValues={ENV.COURSE_CREATION_SETTINGS} />,
      courseCreationSettingsContainer
    )
  }
})
