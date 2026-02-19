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

import {Suspense} from 'react'
import {legacyRender, render} from '@canvas/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import CustomEmojiDenyList from './react/custom_emoji_deny_list/CustomEmojiDenyList'
import CustomHelpLinkSettings from './react/custom_help_link_settings/CustomHelpLinkSettings'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import './jquery/index'
import ready from '@instructure/ready'
import MicrosoftSyncAccountSettings from '@canvas/integrations/react/accounts/microsoft_sync/MicrosoftSyncAccountSettings'
import CourseCreationSettings from './react/course_creation_settings/CourseCreationSettings'
import {InternalSettings} from './react/internal_settings/InternalSettings'
import QuotasTabContent from './react/quotas/QuotasTabContent'
import {initializeTopNavPortal} from '@canvas/top-navigation/react/TopNavPortal'
import SettingsTabs from '../../shared/tabs/SettingsTabs'
import ErrorBoundary from '@canvas/error-boundary'

const I18n = createI18nScope('account_settings_jsx_bundle')

ready(() => {
  const Loading = () => <Spinner size="x-small" renderTitle={I18n.t('Loading')} />
  const ErrorMessage = () => (
    <div className="bcs_check-box">
      <Text color="danger">{I18n.t('Unable to load this control')}</Text>
    </div>
  )

  initializeTopNavPortal()

  const customHelpLinkSettingsContainer = document.getElementById('custom_help_link_settings')

  if (customHelpLinkSettingsContainer) {
    legacyRender(
      <CustomHelpLinkSettings
        {...{
          isCareerAccount: window.ENV.HORIZON_ACCOUNT,
          name: window.ENV.help_link_name,
          icon: window.ENV.help_link_icon,
          links: window.ENV.CUSTOM_HELP_LINKS,
          defaultLinks: window.ENV.DEFAULT_HELP_LINKS,
        }}
      />,
      customHelpLinkSettingsContainer,
    )
  }

  const emojiDenyListContainer = document.getElementById('emoji-deny-list')
  if (emojiDenyListContainer) {
    legacyRender(<CustomEmojiDenyList />, emojiDenyListContainer)
  }

  if (document.getElementById('tab-security-mount')) {
    legacyRender(
      <View as="div" margin="large" padding="large" textAlign="center">
        <Spinner size="large" renderTitle={I18n.t('Loading')} />
      </View>,
      document.getElementById('tab-security-mount'),
    )
  }

  const internalSettingsMountpoint = document.getElementById('tab-internal-settings-mount')
  if (internalSettingsMountpoint) {
    legacyRender(<InternalSettings />, internalSettingsMountpoint)
  }

  if (document.getElementById('tab-integrations-mount')) {
    legacyRender(
      <MicrosoftSyncAccountSettings />,
      document.getElementById('tab-integrations-mount'),
    )
  }

  const courseCreationSettingsContainer = document.getElementById('course_creation_settings')
  if (courseCreationSettingsContainer) {
    legacyRender(
      <CourseCreationSettings currentValues={ENV.COURSE_CREATION_SETTINGS} />,
      courseCreationSettingsContainer,
    )
  }

  if (ENV.ACCOUNT) {
    ready(function () {
      const mountPoint = document.getElementById('quotas_tab_content_mount_point')
      if (mountPoint) {
        render(<QuotasTabContent accountWithQuotas={ENV.ACCOUNT} />, mountPoint)
      }
    })
  }

  const tabsMountpoint = document.getElementById('account_settings_tabs_mount')
  if (tabsMountpoint && tabsMountpoint.dataset.props) {
    const {tabs} = JSON.parse(tabsMountpoint.dataset.props)
    render(
      <Suspense fallback={<Loading />}>
        <ErrorBoundary errorComponent={<ErrorMessage />}>
          <SettingsTabs tabs={tabs} />
        </ErrorBoundary>
      </Suspense>,
      tabsMountpoint,
    )
  }
})
