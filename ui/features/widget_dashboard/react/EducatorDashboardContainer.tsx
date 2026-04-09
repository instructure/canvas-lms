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

import React, {useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {IconSettingsLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import {InstUISettingsProvider} from '@instructure/emotion'
import DashboardNotifications from './components/DashboardNotifications'
import DashboardTabs from './components/DashboardTabs'
import {useWidgetDashboard} from './hooks/useWidgetDashboardContext'
import {useResponsiveContext} from './hooks/useResponsiveContext'
import {useWidgetDashboardEdit} from './hooks/useWidgetDashboardEdit'
import {useWidgetLayout} from './hooks/useWidgetLayout'
import {EDUCATOR_DASHBOARD_THEME} from './educatorDashboardTheme'

const I18n = createI18nScope('widget_dashboard')

const EducatorDashboardContainer = () => {
  const {currentUser, dashboardFeatures} = useWidgetDashboard()
  const {isMobile} = useResponsiveContext()
  const {isEditMode, isDirty, isSaving, saveError, enterEditMode, exitEditMode, clearError} =
    useWidgetDashboardEdit()
  const {resetConfig, saveLayout} = useWidgetLayout()
  const isCustomizationEnabled = dashboardFeatures.widget_dashboard_customization
  const customizeButtonRef = useRef<Element | null>(null)
  const wasEditModeRef = useRef(isEditMode)

  const greeting = currentUser?.display_name
    ? I18n.t('Hi, %{name}!', {name: currentUser.display_name})
    : I18n.t('Hi!')

  useEffect(() => {
    if (wasEditModeRef.current && !isEditMode) {
      ;(customizeButtonRef.current as HTMLElement)?.focus()
    }
    wasEditModeRef.current = isEditMode
  }, [isEditMode])

  useEffect(() => {
    if (!isDirty) return

    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      e.preventDefault()
      e.returnValue = ''
    }

    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [isDirty])

  // Matches WidgetDashboardContainer's handler pattern
  const handleSave = () => {
    saveLayout()
  }

  const handleCancel = () => {
    resetConfig()
    exitEditMode()
  }

  return (
    <InstUISettingsProvider theme={EDUCATOR_DASHBOARD_THEME}>
      <View as="div" data-testid="educator-widget-dashboard">
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
          {isCustomizationEnabled &&
            (isEditMode ? (
              <>
                <Flex.Item>
                  <Button onClick={handleCancel} data-testid="cancel-customize-button">
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
                  elementRef={el => {
                    customizeButtonRef.current = el
                  }}
                  onClick={enterEditMode}
                  renderIcon={<IconSettingsLine />}
                  color="primary"
                  data-testid="customize-dashboard-button"
                >
                  {I18n.t('Customize')}
                </Button>
              </Flex.Item>
            ))}
        </Flex>
        <DashboardTabs />
      </View>
    </InstUISettingsProvider>
  )
}

export default EducatorDashboardContainer
