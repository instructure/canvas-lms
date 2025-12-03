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

import React, {useEffect, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {IconConfigureLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
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
import {useWidgetDashboardEdit} from './hooks/useWidgetDashboardEdit'
import {useWidgetLayout} from './hooks/useWidgetLayout'

const I18n = createI18nScope('widget_dashboard')

const WidgetDashboardContainer: React.FC = () => {
  const {observedUsersList, canAddObservee, currentUser, currentUserRoles, dashboardFeatures} =
    useWidgetDashboard()
  const {isMobile, isDesktop} = useResponsiveContext()
  const {
    isEditMode,
    isDirty,
    isSaving,
    saveError,
    enterEditMode,
    exitEditMode,
    saveChanges,
    clearError,
  } = useWidgetDashboardEdit()
  const {config, resetConfig} = useWidgetLayout()
  const isCustomizationEnabled = dashboardFeatures.widget_dashboard_customization

  const handleChangeObservedUser = useMemo(() => getHandleChangeObservedUser(), [])

  useEffect(() => {
    if (!isDirty) return

    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      e.preventDefault()
      e.returnValue = ''
    }

    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [isDirty])

  const handleSave = () => {
    saveChanges(config)
  }

  const handleCancel = () => {
    resetConfig()
    exitEditMode()
  }

  return (
    <View as="div">
      <DashboardNotifications />
      {saveError && (
        <Alert
          variant="error"
          margin="0 0 medium"
          renderCloseButtonLabel={I18n.t('Close')}
          onDismiss={clearError}
        >
          {I18n.t('Failed to save widget layout: %{error}', {error: saveError})}
        </Alert>
      )}
      <Flex margin="0 0 medium" alignItems="center">
        <Flex.Item shouldGrow>
          <Flex gap="small" direction={isMobile ? 'column' : 'row'} alignItems="center">
            <Flex.Item shouldGrow>
              <Heading level="h1" margin="0" data-testid="dashboard-heading">
                {I18n.t('Dashboard')}
              </Heading>
            </Flex.Item>
            {isCustomizationEnabled && isDesktop && (
              <>
                {isEditMode ? (
                  <>
                    <Flex.Item>
                      <Button
                        onClick={handleCancel}
                        margin="0 small 0 0"
                        data-testid="cancel-customize-button"
                      >
                        {I18n.t('Cancel')}
                      </Button>
                    </Flex.Item>
                    <Flex.Item>
                      <Button
                        color="primary"
                        onClick={handleSave}
                        interaction={isSaving ? 'disabled' : 'enabled'}
                        data-testid="save-customize-button"
                      >
                        {isSaving ? I18n.t('Saving...') : I18n.t('Save changes')}
                      </Button>
                    </Flex.Item>
                  </>
                ) : (
                  <Flex.Item>
                    <Button
                      onClick={enterEditMode}
                      renderIcon={<IconConfigureLine />}
                      withBackground={false}
                      color="primary"
                      data-testid="customize-dashboard-button"
                    >
                      {I18n.t('Customize dashboard')}
                    </Button>
                  </Flex.Item>
                )}
              </>
            )}
            <Flex.Item>
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
                handleChangeObservedUser={handleChangeObservedUser}
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
