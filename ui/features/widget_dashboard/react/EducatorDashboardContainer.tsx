/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {IconSettingsLine} from '@instructure/ui-icons'
import {InstUISettingsProvider} from '@instructure/emotion'
import DashboardNotifications from './components/DashboardNotifications'
import WidgetGrid from './components/WidgetGrid'
import {useWidgetDashboard} from './hooks/useWidgetDashboardContext'
import {useResponsiveContext} from './hooks/useResponsiveContext'
import {useWidgetLayout} from './hooks/useWidgetLayout'
import {EDUCATOR_DASHBOARD_THEME} from './educatorDashboardTheme'

const I18n = createI18nScope('widget_dashboard')

const EducatorDashboardContainer = () => {
  const {currentUser, dashboardFeatures} = useWidgetDashboard()
  const {isMobile} = useResponsiveContext()
  const {config} = useWidgetLayout()
  const isCustomizationEnabled = dashboardFeatures.widget_dashboard_customization

  const greeting = currentUser?.display_name
    ? I18n.t('Hi, %{name}!', {name: currentUser.display_name})
    : I18n.t('Hi!')

  return (
    <InstUISettingsProvider theme={EDUCATOR_DASHBOARD_THEME}>
      <View as="div" data-testid="educator-widget-dashboard">
        <DashboardNotifications />
        <Flex
          margin="0 0 medium x-small"
          gap="small"
          direction={isMobile ? 'column' : 'row'}
          alignItems="center"
        >
          <Flex.Item shouldGrow>
            <Heading level="h1" margin="0" data-testid="educator-dashboard-heading">
              {greeting}
            </Heading>
          </Flex.Item>
          {isCustomizationEnabled && (
            <Flex.Item>
              <Button
                renderIcon={<IconSettingsLine />}
                color="primary"
                data-testid="customize-dashboard-button"
              >
                {I18n.t('Customize')}
              </Button>
            </Flex.Item>
          )}
        </Flex>
        <View as="div" data-testid="educator-dashboard-content" padding="medium 0 0 0">
          <WidgetGrid config={config} />
        </View>
      </View>
    </InstUISettingsProvider>
  )
}

export default EducatorDashboardContainer
