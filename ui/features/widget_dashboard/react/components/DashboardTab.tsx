/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('widget_dashboard')

const DashboardTab: React.FC = () => {
  return (
    <View as="div" padding="medium" data-testid="dashboard-tab-content">
      <Heading level="h2" margin="0 0 medium" data-testid="dashboard-tab-heading">
        {I18n.t('Dashboard')}
      </Heading>
      <Text>
        {I18n.t(
          'Welcome to your dashboard! This is where you can view and manage your dashboard widgets.',
        )}
      </Text>
      <View as="div" margin="medium 0 0">
        <Text size="small" color="secondary">
          {I18n.t('Dashboard widgets and customization features coming soon.')}
        </Text>
      </View>
    </View>
  )
}

export default DashboardTab
