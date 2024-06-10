/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useLayoutEffect, useReducer, useState} from 'react'
import {Navigation as SideNavBar} from '@instructure/ui-navigation'
import {Badge} from '@instructure/ui-badge'
import {CloseButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Avatar} from '@instructure/ui-avatar'
import {Img} from '@instructure/ui-img'
import {
  IconAdminLine,
  IconCalendarMonthLine,
  IconCanvasLogoSolid,
  IconClockLine,
  IconCoursesLine,
  IconDashboardLine,
  IconFolderLine,
  IconHomeLine,
  IconInboxLine,
  IconInfoLine,
  IconLifePreserverLine,
  IconQuestionLine,
  IconSettingsLine,
} from '@instructure/ui-icons'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useQuery} from '@canvas/query'
import {useMutation, useQueryClient} from '@tanstack/react-query'
import {getUnreadCount} from './queries/unreadCountQuery'
import {getActiveItem, getTrayLabel, getTrayPortal, sideNavReducer} from './utils'
import type {ExternalTool} from './utils'
import {getSettingAsync, setSetting} from '@canvas/settings-query/react/settingsQuery'
import {SVGIcon} from '@instructure/ui-svg-images'

const I18n = useI18nScope('sidenav')

const CoursesTray = React.lazy(() => import('./trays/CoursesTray'))
const GroupsTray = React.lazy(() => import('./trays/GroupsTray'))
const AccountsTray = React.lazy(() => import('./trays/AccountsTray'))
const ProfileTray = React.lazy(() => import('./trays/ProfileTray'))
const HistoryTray = React.lazy(() => import('./trays/HistoryTray'))
const HelpTray = React.lazy(() => import('./trays/HelpTray'))

export const InformationIconEnum = {
  INFORMATION: 'information',
  FOLDER: 'folder',
  COG: 'cog',
  LIFE_SAVER: 'lifepreserver',
}

const defaultActiveItem = getActiveItem()

const initialState = {
  isTrayOpen: false,
  activeTray: null,
  selectedNavItem: defaultActiveItem,
  previousSelectedNavItem: defaultActiveItem,
}
interface ISideNav {
  externalTools?: Array<ExternalTool>
}

const SideNav: React.FC<ISideNav> = ({externalTools = []}) => {
  const [collapseSideNav, setCollapseSideNav] = useState(window.ENV.SETTINGS.collapse_global_nav)
  const [state, dispatch] = useReducer(sideNavReducer, initialState)
  const {isTrayOpen, activeTray, selectedNavItem, previousSelectedNavItem} = state

  const {mutate: setCollapseGlobalNav} = useMutation({
    mutationFn: setSetting,
    onSuccess: () =>
      queryClient.invalidateQueries({
        queryKey: ['settings', 'collapse_global_nav'],
      }),
  })

  const updateCollapseGlobalNav = (newState: boolean) => {
    setCollapseSideNav(newState)
    setCollapseGlobalNav({
      setting: 'collapse_global_nav',
      newState,
    })
  }

  const handleActiveTray = useCallback((tray, showActiveTray = false) => {
    if (showActiveTray) {
      dispatch({type: 'SET_ACTIVE_TRAY', payload: tray})
    }

    dispatch({type: 'SET_SELECTED_NAV_ITEM', payload: tray})
  }, [])

  useEffect(() => {
    if (!isTrayOpen) {
      const timer = setTimeout(() => {
        dispatch({type: 'RESET_ACTIVE_TRAY'})
        dispatch({type: 'SET_SELECTED_NAV_ITEM', payload: previousSelectedNavItem})
      }, 100)
      return () => clearTimeout(timer)
    }
  }, [isTrayOpen, previousSelectedNavItem])

  const [trayShouldContainFocus, setTrayShouldContainFocus] = useState(false)
  const [overrideDismiss] = useState(false)

  let logoUrl = null
  const queryClient = useQueryClient()
  const isK5User = window.ENV.K5_USER
  const helpIcon = window.ENV.help_link_icon

  const getHelpIcon = (): JSX.Element => {
    switch (helpIcon) {
      case InformationIconEnum.INFORMATION:
        return <IconInfoLine data-testid="HelpInfo" />
      case InformationIconEnum.FOLDER:
        return <IconFolderLine data-testid="HelpFolder" />
      case InformationIconEnum.COG:
        return <IconSettingsLine data-testid="HelpCog" />
      case InformationIconEnum.LIFE_SAVER:
        return <IconLifePreserverLine data-testid="HelpLifePreserver" />
      default:
        return <IconQuestionLine data-testid="HelpQuestion" />
    }
  }
  const countsEnabled = Boolean(
    window.ENV.current_user_id && !window.ENV.current_user?.fake_student
  )

  const brandConfig =
    (window.ENV.active_brand_config as {
      variables: {'ic-brand-header-image': string}
    }) ?? null
  if (brandConfig) {
    const variables = brandConfig.variables
    logoUrl = variables['ic-brand-header-image']
  }

  const {data: releaseNotesBadgeDisabled} = useQuery({
    queryKey: ['settings', 'release_notes_badge_disabled'],
    queryFn: getSettingAsync,
    enabled: countsEnabled && ENV.FEATURES.embedded_release_notes,
    fetchAtLeastOnce: true,
  })

  const {data: unreadContentSharesCount} = useQuery({
    queryKey: ['unread_count', 'content_shares'],
    queryFn: getUnreadCount,
    staleTime: 60 * 60 * 1000, // 1 hour
    enabled: countsEnabled && ENV.CAN_VIEW_CONTENT_SHARES,
    refetchOnWindowFocus: true,
  })

  const {data: unreadConversationsCount} = useQuery({
    queryKey: ['unread_count', 'conversations'],
    queryFn: getUnreadCount,
    staleTime: 2 * 60 * 1000, // two minutes
    enabled: countsEnabled && !ENV.current_user_disabled_inbox,
    broadcast: true,
    refetchOnWindowFocus: true,
  })

  const {data: unreadReleaseNotesCount} = useQuery({
    queryKey: ['unread_count', 'release_notes'],
    queryFn: getUnreadCount,
    enabled: countsEnabled && ENV.FEATURES.embedded_release_notes && !releaseNotesBadgeDisabled,
  })

  useLayoutEffect(() => {
    const collapseDiv = document.querySelectorAll('[aria-label="Main navigation"]')[0]
      .childNodes[1] as HTMLElement
    const collapseButton = collapseDiv.childNodes[0] as HTMLElement
    collapseButton.id = 'sidenav-toggle'

    if (collapseSideNav) document.body.classList.remove('primary-nav-expanded')
    else document.body.classList.add('primary-nav-expanded')
  }, [collapseSideNav, selectedNavItem])

  return (
    <>
      <SideNavBar
        id="instui-sidenav"
        label="Main navigation"
        toggleLabel={{
          expandedLabel: 'Minimize Navigation',
          minimizedLabel: 'Expand Navigation',
        }}
        defaultMinimized={collapseSideNav}
        onMinimized={e =>
          e.nativeEvent.type === 'click' && updateCollapseGlobalNav(!collapseSideNav)
        }
        themeOverride={{
          minimizedWidth: '100%',
          toggleTransition: '200ms',
        }}
        data-testid="sidenav-container"
      >
        <SideNavBar.Item
          id="logomark"
          icon={
            !logoUrl ? (
              <IconCanvasLogoSolid
                data-testid="sidenav-canvas-logo"
                size={collapseSideNav ? 'small' : 'medium'}
                // unsure why this is necessary?
                style={{display: 'none'}}
              />
            ) : (
              <Img
                display="inline-block"
                alt="sidenav-brand-logomark"
                src={logoUrl}
                data-testid="sidenav-brand-logomark"
              />
            )
          }
          label={<ScreenReaderContent>{I18n.t('Home')}</ScreenReaderContent>}
          href="/"
          minimized={collapseSideNav}
          data-testid="sidenav-header-logo"
        />
        <SideNavBar.Item
          id="profile-tray"
          icon={
            <Badge
              count={unreadContentSharesCount}
              formatOutput={(count: string) =>
                (unreadContentSharesCount || 0) > 0 ? (
                  <AccessibleContent
                    alt={I18n.t(
                      {
                        one: 'One unread share.',
                        other: '%{count} unread shares.',
                      },
                      {count}
                    )}
                  >
                    {count}
                  </AccessibleContent>
                ) : (
                  ''
                )
              }
            >
              <Avatar
                id="user-avatar"
                name={window.ENV.current_user.display_name}
                size={collapseSideNav ? 'x-small' : 'small'}
                src={window.ENV.current_user.avatar_image_url}
                data-testid="sidenav-user-avatar"
                showBorder="always"
                frameBorder={4}
                themeOverride={{
                  background: 'transparent',
                  borderColor: '#ffffff',
                  borderWidthSmall: '2px',
                  borderWidthMedium: '2px',
                }}
              />
            </Badge>
          }
          label={I18n.t('Account')}
          href="/profile/settings"
          onClick={event => {
            event.preventDefault()
            handleActiveTray('profile', true)
          }}
          selected={selectedNavItem === 'profile'}
          data-selected={selectedNavItem === 'profile'}
          themeOverride={{
            fontWeight: 400,
          }}
          minimized={collapseSideNav}
        />
        <SideNavBar.Item
          id="accounts-tray"
          icon={<IconAdminLine />}
          label={I18n.t('Admin')}
          href="/accounts"
          onClick={event => {
            event.preventDefault()
            handleActiveTray('accounts', true)
          }}
          selected={selectedNavItem === 'accounts'}
          data-selected={selectedNavItem === 'accounts'}
          themeOverride={{
            fontWeight: 400,
          }}
          minimized={collapseSideNav}
        />
        <SideNavBar.Item
          id="dashboard-tray"
          icon={isK5User ? <IconHomeLine data-testid="K5HomeIcon" /> : <IconDashboardLine />}
          label={isK5User ? I18n.t('Home') : I18n.t('Dashboard')}
          href="/"
          onClick={() => handleActiveTray('dashboard')}
          selected={selectedNavItem === 'dashboard' || selectedNavItem === ''}
          data-selected={selectedNavItem === 'dashboard' || selectedNavItem === ''}
          themeOverride={{
            fontWeight: 400,
          }}
          minimized={collapseSideNav}
        />
        <SideNavBar.Item
          id="courses-tray"
          icon={<IconCoursesLine />}
          label={isK5User ? I18n.t('Subjects') : I18n.t('Courses')}
          href="/courses"
          onClick={event => {
            event.preventDefault()
            handleActiveTray('courses', true)
          }}
          selected={selectedNavItem === 'courses'}
          data-selected={selectedNavItem === 'courses'}
          themeOverride={{
            fontWeight: 400,
          }}
          minimized={collapseSideNav}
        />
        <SideNavBar.Item
          id="calendar-tray"
          icon={<IconCalendarMonthLine />}
          label={I18n.t('Calendar')}
          href="/calendar"
          onClick={() => handleActiveTray('calendar')}
          selected={selectedNavItem === 'calendar'}
          data-selected={selectedNavItem === 'calendar'}
          themeOverride={{
            fontWeight: 400,
          }}
          minimized={collapseSideNav}
        />
        <SideNavBar.Item
          id="conversations-tray"
          icon={
            <Badge
              count={unreadConversationsCount}
              formatOutput={(count: string) =>
                (unreadConversationsCount || 0) > 0 ? (
                  <AccessibleContent
                    alt={I18n.t(
                      {
                        one: 'One unread message.',
                        other: '%{count} unread messages.',
                      },
                      {count}
                    )}
                  >
                    {count}
                  </AccessibleContent>
                ) : (
                  ''
                )
              }
            >
              <IconInboxLine />
            </Badge>
          }
          label={I18n.t('Inbox')}
          href="/conversations"
          onClick={() => handleActiveTray('conversations')}
          selected={selectedNavItem === 'conversations'}
          data-selected={selectedNavItem === 'conversations'}
          themeOverride={{
            fontWeight: 400,
          }}
          minimized={collapseSideNav}
        />
        <SideNavBar.Item
          id="history-tray"
          icon={<IconClockLine />}
          label={I18n.t('History')}
          href={window.ENV.page_view_update_url}
          onClick={event => {
            event.preventDefault()
            handleActiveTray('history', true)
          }}
          selected={selectedNavItem === 'history'}
          data-selected={selectedNavItem === 'history'}
          themeOverride={{
            fontWeight: 400,
          }}
          minimized={collapseSideNav}
        />

        {Array.isArray(externalTools) &&
          [...externalTools].map(tool => {
            const toolId = tool.label.toLowerCase().replaceAll(' ', '-')
            const toolImg = tool.imgSrc ? tool.imgSrc : ''
            return (
              <SideNavBar.Item
                key={toolId}
                id={`${toolId}-external-tool-tray`}
                icon={
                  'svgPath' in tool ? (
                    <SVGIcon viewBox="0 0 64 64" src={tool.svgPath} title="svg-external-tool" />
                  ) : (
                    <Img width="26px" height="26px" src={toolImg} alt="" />
                  )
                }
                label={tool.label}
                href={`${tool.href?.toString()}&toolId=${toolId}`}
                onClick={() => handleActiveTray(toolId)}
                selected={selectedNavItem === toolId}
                data-selected={selectedNavItem === toolId}
                themeOverride={{
                  fontWeight: 400,
                }}
                minimized={collapseSideNav}
              />
            )
          })}
        <SideNavBar.Item
          id="help-tray"
          icon={
            <Badge
              count={unreadReleaseNotesCount}
              formatOutput={(count: string) =>
                (unreadReleaseNotesCount || 0) > 0 ? (
                  <AccessibleContent
                    alt={I18n.t(
                      {
                        one: 'One unread release note.',
                        other: '%{count} unread release notes.',
                      },
                      {count}
                    )}
                  >
                    {count}
                  </AccessibleContent>
                ) : (
                  ''
                )
              }
            >
              {getHelpIcon()}
            </Badge>
          }
          label={I18n.t('Help')}
          href="https://help.instructure.com/"
          onClick={event => {
            event.preventDefault()
            handleActiveTray('help', true)
          }}
          selected={selectedNavItem === 'help'}
          data-selected={selectedNavItem === 'help'}
          themeOverride={{
            fontWeight: 400,
          }}
          minimized={collapseSideNav}
        />
      </SideNavBar>
      <Tray
        key={activeTray}
        label={getTrayLabel(activeTray)}
        size="small"
        open={isTrayOpen}
        // We need to override closing trays
        // so the tour can properly go through them
        // without them unexpectedly closing.
        onDismiss={
          overrideDismiss
            ? () => {}
            : () => {
                dispatch({type: 'SET_IS_TRAY_OPEN', payload: false})
                setTrayShouldContainFocus(false)
              }
        }
        shouldCloseOnDocumentClick={true}
        shouldContainFocus={trayShouldContainFocus}
        mountNode={getTrayPortal()}
        themeOverride={{smallWidth: '28em'}}
      >
        <div className={`navigation-tray-container ${activeTray}-tray`}>
          <CloseButton
            placement="end"
            onClick={() => {
              dispatch({type: 'SET_IS_TRAY_OPEN', payload: false})
              setTrayShouldContainFocus(false)
            }}
            screenReaderLabel={I18n.t('Close')}
          />
          <div className="tray-with-space-for-global-nav">
            <React.Suspense
              fallback={
                <View display="block" textAlign="center">
                  <Spinner
                    size="large"
                    delay={200}
                    margin="large auto"
                    renderTitle={() => I18n.t('Loading')}
                  />
                </View>
              }
            >
              {activeTray === 'accounts' && <AccountsTray />}
              {activeTray === 'courses' && <CoursesTray />}
              {activeTray === 'groups' && <GroupsTray />}
              {activeTray === 'profile' && <ProfileTray />}
              {activeTray === 'history' && <HistoryTray />}
              {activeTray === 'help' && (
                <HelpTray closeTray={() => dispatch({type: 'SET_IS_TRAY_OPEN', payload: false})} />
              )}
            </React.Suspense>
          </div>
        </div>
      </Tray>
    </>
  )
}

export default SideNav
