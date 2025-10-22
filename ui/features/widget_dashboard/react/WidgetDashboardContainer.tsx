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
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import DashboardTabs from './components/DashboardTabs'
import DashboardNotifications from './components/DashboardNotifications'
import ObserverOptions from '@canvas/observer-picker'
import {
  getHandleChangeObservedUser,
  autoFocusObserverPicker,
} from '@canvas/observer-picker/util/pageReloadHelper'
import {useWidgetDashboard} from './hooks/useWidgetDashboardContext'
import FeedbackQuestionTile from './components/FeedbackQuestionTile'
import {useResponsiveContext} from './hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

const WidgetDashboardContainer: React.FC = () => {
  const {observedUsersList, canAddObservee, currentUser, currentUserRoles} = useWidgetDashboard()
  const {isMobile} = useResponsiveContext()

  return (
    <View as="div">
      <DashboardNotifications />
      <Flex margin="0 0 medium" alignItems="center">
        <Flex.Item shouldGrow>
          <Flex gap="small" direction={isMobile ? 'column' : 'row'}>
            <Flex.Item shouldGrow>
              <Heading level="h1" margin="0" data-testid="dashboard-heading">
                {I18n.t('Dashboard')}
              </Heading>
            </Flex.Item>
            <Flex.Item padding="small">
              <FeedbackQuestionTile />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        {observedUsersList.length > 0 && currentUser && (
          <Flex.Item>
            <View as="div">
              <ObserverOptions
                autoFocus={autoFocusObserverPicker()}
                canAddObservee={canAddObservee}
                currentUserRoles={currentUserRoles}
                currentUser={currentUser}
                handleChangeObservedUser={getHandleChangeObservedUser()}
                observedUsersList={observedUsersList}
                renderLabel={I18n.t(
                  'Select a student to view. The page will refresh automatically.',
                )}
              />
            </View>
          </Flex.Item>
        )}
      </Flex>
      <DashboardTabs />
    </View>
  )
}

export default WidgetDashboardContainer
