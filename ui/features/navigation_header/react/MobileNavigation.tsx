/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React, {useContext, useEffect, useState, useRef} from 'react'
import $ from 'jquery'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {useQuery} from '@tanstack/react-query'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getUnreadCount} from './queries/unreadCountQuery'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {sessionStoragePersister} from '@canvas/query'
import {DynamicInstUISettingsProvider} from '@canvas/instui-bindings/react/DynamicInstUISettingProvider'
import {getTheme} from '@canvas/instui-bindings'
import {List} from '@instructure/ui-list'
import {ThemeOrOverride} from '@instructure/emotion/types/EmotionTypes'

declare global {
  interface Window {
    openBPSidebar: () => void
  }
}

const I18n = createI18nScope('MobileNavigation')

const mobileHeaderInboxUnreadBadge = document.getElementById('mobileHeaderInboxUnreadBadge')

const MobileContextMenu = React.lazy(() => import('./MobileContextMenu'))
const MobileGlobalMenu = React.lazy(() => import('./MobileGlobalMenu'))

const MobileNavigation: React.FC<{navIsOpen?: boolean}> = ({navIsOpen = false}) => {
  const {setOnSuccess} = useContext(AlertManagerContext)

  const [globalNavIsOpen, setGlobalNavIsOpen] = useState(navIsOpen)
  const [contextNavIsOpen, setContextNavIsOpen] = useState(false)
  const firstRender = useRef(true)

  const countsEnabled = Boolean(
    window.ENV.current_user_id && !window.ENV.current_user?.fake_student,
  )

  const {data: unreadConversationsCount, isSuccess: hasUnreadConversationsCount} = useQuery({
    queryKey: ['unread_count', 'conversations'],
    queryFn: getUnreadCount,
    staleTime: 2 * 60 * 1000, // two minutes
    enabled: countsEnabled && !ENV.current_user_disabled_inbox,
    persister: sessionStoragePersister,
  })

  useEffect(() => {
    if (hasUnreadConversationsCount && mobileHeaderInboxUnreadBadge) {
      mobileHeaderInboxUnreadBadge.style.display = unreadConversationsCount > 0 ? '' : 'none'
    }
  }, [hasUnreadConversationsCount, unreadConversationsCount])

  useEffect(() => {
    $('.mobile-header-hamburger').on('touchstart click', event => {
      event.preventDefault()
      setGlobalNavIsOpen(true)
    })

    $('.mobile-header-blueprint-button').on('touchstart click', () => {
      window.openBPSidebar()
    })

    $('.mobile-header-title.expandable, .mobile-header-arrow').on('touchstart click', event => {
      event.preventDefault()
      setContextNavIsOpen(prev => !prev)
    })
  }, [])

  useEffect(() => {
    const arrowIcon = document.getElementById('mobileHeaderArrowIcon')
    const mobileContextNavContainer = document.getElementById('mobileContextNavContainer')

    // gotta do some manual dom manip for the non-react arrow/close icon
    if (arrowIcon) {
      arrowIcon.className = contextNavIsOpen ? 'icon-x' : 'icon-arrow-open-down'
    }

    if (mobileContextNavContainer) {
      mobileContextNavContainer.setAttribute('aria-expanded', contextNavIsOpen.toString())
    }

    if (!firstRender.current) {
      const message = contextNavIsOpen
        ? I18n.t('Navigation menu is now open')
        : I18n.t('Navigation menu is now closed')
      setOnSuccess(message, true)
    }
  }, [contextNavIsOpen, setOnSuccess])

  useEffect(() => {
    if (!firstRender.current) {
      const message = globalNavIsOpen
        ? I18n.t('Global navigation menu is now open')
        : I18n.t('Global navigation menu is now closed')
      setOnSuccess(message, true)
    }
  }, [globalNavIsOpen, setOnSuccess])

  useEffect(() => {
    firstRender.current = false
  }, [])

  const spinner = (
    <View display="block" textAlign="center">
      <Spinner size="large" margin="large auto" renderTitle={() => I18n.t('...Loading')} />
    </View>
  )

  function updatedTheme(currentTheme: any): {
    isThemeOverrideActive: boolean
    themeOverride: ThemeOrOverride
  } {
    const textColor = currentTheme['ic-brand-global-nav-menu-item__text-color']
    const avatarBorderColor = currentTheme['ic-brand-global-nav-avatar-border']
    const trayBackground = currentTheme['ic-brand-global-nav-bgd']
    const iconColor = currentTheme['ic-brand-global-nav-ic-icon-svg-fill']
    if (
      !textColor ||
      !avatarBorderColor ||
      !trayBackground ||
      !iconColor ||
      currentTheme.key === 'canvas-high-contrast'
    ) {
      // if none of these variables are defined, return a basic override to avoid
      // unexpected a11y issues and make Link/ToggleDetails coloring consistent
      const linkColor = currentTheme['ic-link-color'] || 'var(--ic-link-color)'
      return {
        isThemeOverrideActive: false,
        themeOverride: {
          componentOverrides: {
            Text: {
              brandColor: linkColor,
            },
            ToggleDetails: {
              textColor: linkColor,
              iconColor: linkColor,
              toggleFocusBorderColor: linkColor,
            },
            Link: {
              focusOutlineColor: linkColor,
            },
          },
        },
      }
    }

    const themeOverride = {
      componentOverrides: {
        Avatar: {
          borderColor: avatarBorderColor,
        },
        Text: {
          brandColor: textColor,
          primaryColor: textColor,
          secondaryColor: textColor,
        },
        Link: {
          focusOutlineColor: textColor,
          color: textColor,
        },
        ToggleDetails: {
          textColor: textColor,
          iconColor: iconColor,
          toggleFocusBorderColor: textColor,
        },
        // for HistoryList entries, which inherits their color from List.Item
        [List.Item.componentId]: {
          color: textColor,
        },
        Tray: {
          background: trayBackground,
        },
      },
    }
    return {isThemeOverrideActive: true, themeOverride}
  }

  const renderTray = (isThemeOverrideActive: boolean) => {
    return (
      <Tray
        size="large"
        label={I18n.t('Global Navigation')}
        open={globalNavIsOpen}
        onDismiss={() => setGlobalNavIsOpen(false)}
        shouldCloseOnDocumentClick={true}
      >
        {globalNavIsOpen && (
          <React.Suspense fallback={spinner}>
            <MobileGlobalMenu
              onDismiss={() => setGlobalNavIsOpen(false)}
              isThemeOverrideActive={isThemeOverrideActive}
            />
          </React.Suspense>
        )}
      </Tray>
    )
  }

  const currentTheme = getTheme() as any
  const override = updatedTheme(currentTheme)
  return (
    <>
      {globalNavIsOpen && (
        <DynamicInstUISettingsProvider theme={override.themeOverride}>
          {renderTray(override.isThemeOverrideActive)}
        </DynamicInstUISettingsProvider>
      )}
      {contextNavIsOpen && (
        <React.Suspense fallback={spinner}>
          <MobileContextMenu spinner={spinner} />
        </React.Suspense>
      )}
    </>
  )
}

export default MobileNavigation
