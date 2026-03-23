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

import React, {useCallback, useEffect, useMemo, useState} from 'react'
import {render} from '@canvas/react'
import WidgetDashboardContainer from './react/WidgetDashboardContainer'
import EducatorDashboardContainer from './react/EducatorDashboardContainer'
import ready from '@instructure/ready'
import {useScope as createI18nScope} from '@canvas/i18n'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@instructure/platform-images/assets/ErrorShip.svg'
import {
  WidgetDashboardProvider,
  WidgetDashboardEditProvider,
  WidgetLayoutProvider,
  ResponsiveProvider,
} from '@instructure/platform-widget-dashboard'
import {Responsive} from '@instructure/ui-responsive'
import {InstUISettingsProvider} from '@instructure/emotion'
import {PlatformBridge} from './react/platformBridge'
import {WidgetThemeProvider} from './react/theme/WidgetThemeContext'
import {darkColors} from './react/theme/darkThemeColors'

const I18n = createI18nScope('widget_dashboard')

const RESPONSIVE_QUERY = {
  mobile: {maxWidth: '639px'},
  tablet: {minWidth: '640px', maxWidth: '1379px'},
  desktop: {minWidth: '1380px'},
}

function buildDarkThemeOverride(isDark: boolean) {
  if (!isDark) return {}
  const c = darkColors
  return {
    componentOverrides: {
      View: {
        backgroundPrimary: c.cardBackground,
        backgroundSecondary: c.cardSecondary,
        borderColorPrimary: c.border,
        borderColorSecondary: c.border,
        color: c.textPrimary,
      },
      Heading: {
        primaryColor: c.textPrimary,
        secondaryColor: c.textSecondary,
      },
      Text: {
        primaryColor: c.textPrimary,
        secondaryColor: c.textSecondary,
        primaryInverseColor: c.pageBackground,
      },
      'Tabs.Tab': {
        defaultColor: c.textPrimary,
        secondaryColor: c.textPrimary,
        defaultSelectedBorderColor: c.textLink,
      },
      Tabs: {
        defaultBackground: c.pageBackground,
        scrollFadeColor: c.pageBackground,
      },
      'Tabs.Panel': {
        color: c.textPrimary,
        background: c.pageBackground,
      },
      Link: {
        color: c.textLink,
      },
      Checkbox: {
        labelColor: c.textPrimary,
      },
      FormFieldLabel: {
        color: c.textSecondary,
      },
      TextInput: {
        color: c.textPrimary,
        background: c.inputBackground,
        borderColor: c.inputBorder,
      },
      Avatar: {
        background: c.cardSecondary,
        borderColor: c.border,
        color: c.textLink,
      },
      Pill: {
        background: c.cardSecondary,
        primaryColor: c.textSecondary,
      },
      Options: {
        background: c.cardBackground,
        labelColor: c.textSecondary,
      },
      'Options.Item': {
        color: c.textPrimary,
        background: c.cardBackground,
        highlightedBackground: c.cardSecondary,
        highlightedLabelColor: c.textPrimary,
        selectedBackground: c.textLink,
        selectedLabelColor: '#FFFFFF',
      },
      IconButton: {
        primaryInverseBackground: c.cardSecondary,
        primaryInverseHoverBackground: c.border,
        primaryInverseActiveBackground: c.cardSecondary,
        primaryInverseColor: c.textPrimary,
        primaryInverseBorderColor: 'transparent',
        secondaryBackground: c.cardSecondary,
        secondaryHoverBackground: c.border,
        secondaryActiveBackground: c.cardSecondary,
        secondaryColor: c.textPrimary,
        secondaryBorderColor: c.border,
      },
    },
  }
}

const WidgetDashboardApp = () => {
  const isDarkModeEnabled = !!ENV.DASHBOARD_FEATURES?.widget_dashboard_dark_mode
  const initialDark = isDarkModeEnabled && !!ENV.WIDGET_DASHBOARD_DARK_MODE
  const [isDark, setIsDark] = useState(initialDark)
  const darkOverride = useMemo(() => buildDarkThemeOverride(isDark), [isDark])
  const handleSetIsDark = useCallback((value: boolean) => setIsDark(value), [])

  useEffect(() => {
    const content = document.getElementById('content')
    if (!content) return

    let styleEl: HTMLStyleElement | null = null
    if (isDark) {
      content.style.backgroundColor = darkColors.pageBackground
      styleEl = document.createElement('style')
      styleEl.id = 'widget-dashboard-dark-mode'
      styleEl.textContent = `
        #content [class$="-view"],
        #content [class*="-view "],
        #content [class*="-view-"],
        #content [class$="-heading"],
        #content [class*="-heading "],
        #content [class*="-formFieldLayout__label"],
        #content [class*="-toggleDetails__summary"],
        #content [class*="-list__item"],
        #content [class*="-listItem"],
        #content [class*="-select"] {
          color: ${darkColors.textPrimary} !important;
        }
        #content [class*="-textInput__facade"] {
          background: ${darkColors.inputBackground} !important;
          border-color: ${darkColors.inputBorder} !important;
          color: ${darkColors.textPrimary} !important;
        }
        #content input[class*="-textInput__input"] {
          color: ${darkColors.textPrimary} !important;
        }
        #content [class*="-avatar__initials"] {
          background: ${darkColors.cardSecondary} !important;
        }
        #content [class*="-pill__"] {
          background: ${darkColors.cardSecondary} !important;
        }
        body [class*="-options"] {
          background: ${darkColors.cardBackground} !important;
        }
        body [class*="-options__item"] {
          color: ${darkColors.textPrimary} !important;
          background: ${darkColors.cardBackground} !important;
        }
        body [class*="-options__item"][aria-selected="true"] {
          background: ${darkColors.textLink} !important;
          color: #FFFFFF !important;
        }
        body [class*="-options__item"]:hover,
        body [class*="-options__item"][data-highlighted] {
          background: ${darkColors.cardSecondary} !important;
        }
        #content [class*="-link"] a,
        #content a[class*="-link"] {
          color: ${darkColors.textLink} !important;
        }
      `
      document.head.appendChild(styleEl)
    } else {
      content.style.backgroundColor = ''
      const existing = document.getElementById('widget-dashboard-dark-mode')
      if (existing) existing.remove()
    }
    return () => {
      if (content) {
        content.style.backgroundColor = ''
      }
      const existing = document.getElementById('widget-dashboard-dark-mode')
      if (existing) existing.remove()
    }
  }, [isDark])

  return (
    <ErrorBoundary
      errorComponent={
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorCategory={I18n.t('Widget Dashboard Error Page')}
        />
      }
    >
      <PlatformBridge>
        <WidgetDashboardProvider
          preferences={ENV.PREFERENCES}
          observedUsersList={ENV.OBSERVED_USERS_LIST}
          canAddObservee={ENV.CAN_ADD_OBSERVEE}
          currentUser={ENV.current_user}
          observedUserId={ENV.OBSERVED_USER_ID}
          currentUserRoles={ENV.current_user_roles}
          sharedCourseData={ENV.SHARED_COURSE_DATA}
          dashboardFeatures={ENV.DASHBOARD_FEATURES}
        >
          <WidgetDashboardEditProvider>
            <WidgetLayoutProvider>
              <InstUISettingsProvider theme={darkOverride}>
                <WidgetThemeProvider isDark={isDark} setIsDark={handleSetIsDark}>
                  <Responsive
                    match="media"
                    query={RESPONSIVE_QUERY}
                    render={(_props, matches) => (
                      <ResponsiveProvider matches={matches || ['desktop']}>
                        {ENV.DASHBOARD_FEATURES?.educator_dashboard ? (
                          <EducatorDashboardContainer />
                        ) : (
                          <WidgetDashboardContainer />
                        )}
                      </ResponsiveProvider>
                    )}
                  />
                </WidgetThemeProvider>
              </InstUISettingsProvider>
            </WidgetLayoutProvider>
          </WidgetDashboardEditProvider>
        </WidgetDashboardProvider>
      </PlatformBridge>
    </ErrorBoundary>
  )
}

ready(() => {
  const container = document.getElementById('content')

  if (container) {
    render(<WidgetDashboardApp />, container)
  }
})
