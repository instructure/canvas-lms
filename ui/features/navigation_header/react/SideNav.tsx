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

import React, {useEffect, useRef, useState} from 'react'
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
import {getSetting, setSetting} from './queries/settingsQuery'
import {getActiveItem, getTrayLabel, getTrayPortal} from './utils'
import type {ActiveTray} from './utils'

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

const SideNav = () => {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const [activeTray, setActiveTray] = useState<ActiveTray | null>(null)
  const [selectedNavItem, setSelectedNavItem] = useState<ActiveTray | ''>(defaultActiveItem)
  const sideNavRef = useRef<HTMLDivElement | null>(null)
  const accountRef = useRef<Element | null>(null)
  const dashboardRef = useRef<Element | null>(null)
  const coursesRef = useRef<Element | null>(null)
  const adminRef = useRef<Element | null>(null)
  const calendarRef = useRef<Element | null>(null)
  const inboxRef = useRef<Element | null>(null)
  const helpRef = useRef<Element | null>(null)
  const avatarRef = useRef<Element | null>(null)

  // after tray is closed, eventually set activeTray to null
  // we don't do this immediately in order to maintain animation of closing tray
  useEffect(() => {
    if (!isTrayOpen) {
      setTimeout(() => setActiveTray(null), 150)
    }
  }, [isTrayOpen])

  useEffect(() => {
    // when an active tray is set, we infer that the tray is opened
    if (activeTray) {
      setIsTrayOpen(true)
    }

    // if the active tray is set to null, the active nav item should be
    // determined by page location
    setSelectedNavItem(activeTray ?? defaultActiveItem)
  }, [activeTray])

  useEffect(() => {
    if (sideNavRef.current instanceof HTMLElement) {
      const active = sideNavRef.current.querySelector('[data-selected="true"]')
      if (active instanceof HTMLAnchorElement) {
        active.dataset.selected = ''
      }
    }

    switch (selectedNavItem) {
      case 'profile':
        if (accountRef.current instanceof HTMLElement) {
          accountRef.current.dataset.selected = 'true'
        }
        break

      case 'accounts':
        if (adminRef.current instanceof HTMLElement) {
          adminRef.current.dataset.selected = 'true'
        }
        break

      case 'dashboard':
        if (dashboardRef.current instanceof HTMLElement) {
          dashboardRef.current.dataset.selected = 'true'
        }
        break
      case 'conversations':
        if (adminRef.current instanceof HTMLElement) {
          adminRef.current.dataset.selected = 'true'
        }
        break
      case 'courses':
        if (coursesRef.current instanceof HTMLElement) {
          coursesRef.current.dataset.selected = 'true'
        }
        break
      case 'help':
        if (helpRef.current instanceof HTMLElement) {
          helpRef.current.dataset.selected = 'true'
        }
        break
    }
  }, [selectedNavItem])

  const [trayShouldContainFocus, setTrayShouldContainFocus] = useState(false)
  const [overrideDismiss] = useState(false)

  let logoUrl = null
  const queryClient = useQueryClient()
  const isK5User = window.ENV.K5_USER
  const helpIcon = window.ENV.help_link_icon

  const navItemThemeOverride = {
    iconColor: 'white',
    contentPadding: '0.1rem',
    backgroundColor: 'transparent',
    hoverBackgroundColor: 'transparent',
  }

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
    queryFn: getSetting,
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

  const {data: collapseGlobalNav} = useQuery({
    queryKey: ['settings', 'collapse_global_nav'],
    queryFn: getSetting,
    enabled: true,
    fetchAtLeastOnce: true,
  })

  const setCollapseGlobalNav = useMutation({
    mutationFn: setSetting,
    onSuccess: () =>
      queryClient.invalidateQueries({
        queryKey: ['settings', 'collapse_global_nav'],
      }),
  })

  function updateCollapseGlobalNav(newState: boolean) {
    setCollapseGlobalNav.mutate({
      setting: 'collapse_global_nav',
      newState,
    })
  }

  useEffect(() => {
    if (collapseGlobalNav) document.body.classList.remove('primary-nav-expanded')
    else document.body.classList.add('primary-nav-expanded')

    if (avatarRef.current instanceof HTMLElement)
      avatarRef.current.setAttribute('user-avatar', 'true')
  }, [collapseGlobalNav])

  return (
    <div
      ref={sideNavRef}
      style={{width: '100%', height: '100vh'}}
      className="sidenav-container"
      data-testid="sidenav-container"
    >
      <style>{`
        .sidenav-container a {
          padding: 0.4375rem 0;
          font-weight: 400;
          transition: background-color 0.3s, padding 0.3s;
        }
        .sidenav-container a:hover {
          text-decoration: inherit;
          background-color: rgba(0, 0, 0, 0.2);
        }
        .sidenav-container a > div:first-child {
          display: flex;
          justify-content: center;
        }
        .sidenav-container a > div:nth-child(2) {
          margin: 3px 0 0;
        }
        .canvas-logo {
          width: ${!collapseGlobalNav ? '2.63rem' : '1.695rem'} !important;
          height: ${!collapseGlobalNav ? '2.63rem' : '1.695rem'} !important;
        }
        .sidenav-container span[user-avatar="true"] {
          width: ${!collapseGlobalNav ? '36px' : '30px'};
          height: ${!collapseGlobalNav ? '36px' : '30px'};
          border: 2px solid var(--ic-brand-global-nav-avatar-border) !important;
        }
        .sidenav-container a[data-selected="true"]:hover {
          color: var(--ic-brand-primary);
          background-color: var(--ic-brand-global-nav-menu-item__text-color);
        }
      `}</style>
      <SideNavBar
        label="Main navigation"
        toggleLabel={{
          expandedLabel: 'Minimize Navigation',
          minimizedLabel: 'Expand Navigation',
        }}
        defaultMinimized={collapseGlobalNav}
        onMinimized={() => updateCollapseGlobalNav(!collapseGlobalNav)}
        themeOverride={{
          minimizedWidth: '100%',
        }}
      >
        <SideNavBar.Item
          icon={
            !logoUrl ? (
              <div
                style={{
                  margin: `${!collapseGlobalNav ? '0.825rem' : '0.5395rem'} 0 ${
                    !collapseGlobalNav ? '0.435rem' : '0.4rem'
                  } 0`,
                }}
              >
                <IconCanvasLogoSolid className="canvas-logo" data-testid="sidenav-canvas-logo" />
              </div>
            ) : (
              <div
                style={{
                  margin: `${!collapseGlobalNav ? '-0.4rem' : '0.275rem'} 0 ${
                    !collapseGlobalNav ? '-0.905rem' : '-0.275rem'
                  } 0`,
                }}
              >
                <Img
                  display="inline-block"
                  alt="sidenav-brand-logomark"
                  src={logoUrl}
                  data-testid="sidenav-brand-logomark"
                />
              </div>
            )
          }
          label={<ScreenReaderContent>{I18n.t('Home')}</ScreenReaderContent>}
          href="/"
          themeOverride={{
            ...navItemThemeOverride,
            contentPadding: '0',
          }}
          data-testid="sidenav-header-logo"
        />
        <SideNavBar.Item
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
                elementRef={el => (avatarRef.current = el)}
                name={window.ENV.current_user.display_name}
                size="x-small"
                src={window.ENV.current_user.avatar_image_url}
                data-testid="sidenav-user-avatar"
                themeOverride={{
                  background: 'transparent',
                }}
              />
            </Badge>
          }
          elementRef={el => (accountRef.current = el)}
          label={I18n.t('Account')}
          href="/profile/settings"
          onClick={event => {
            event.preventDefault()
            setActiveTray('profile')
          }}
          selected={selectedNavItem === 'profile'}
          themeOverride={navItemThemeOverride}
        />
        <SideNavBar.Item
          elementRef={el => (adminRef.current = el)}
          icon={<IconAdminLine />}
          label={I18n.t('Admin')}
          href="/accounts"
          onClick={event => {
            event.preventDefault()
            setActiveTray('accounts')
          }}
          selected={selectedNavItem === 'accounts'}
          themeOverride={navItemThemeOverride}
        />
        <SideNavBar.Item
          elementRef={el => (dashboardRef.current = el)}
          icon={isK5User ? <IconHomeLine data-testid="K5HomeIcon" /> : <IconDashboardLine />}
          label={isK5User ? I18n.t('Home') : I18n.t('Dashboard')}
          href="/"
          themeOverride={navItemThemeOverride}
          selected={selectedNavItem === 'dashboard'}
        />
        <SideNavBar.Item
          elementRef={el => (coursesRef.current = el)}
          id={selectedNavItem === 'courses' ? 'active-courses' : ''}
          icon={<IconCoursesLine />}
          label={isK5User ? I18n.t('Subjects') : I18n.t('Courses')}
          href="/courses"
          onClick={event => {
            event.preventDefault()
            setActiveTray('courses')
          }}
          selected={selectedNavItem === 'courses'}
          themeOverride={navItemThemeOverride}
        />
        <SideNavBar.Item
          elementRef={el => (calendarRef.current = el)}
          icon={<IconCalendarMonthLine />}
          label={I18n.t('Calendar')}
          href="/calendar"
          themeOverride={navItemThemeOverride}
          selected={selectedNavItem === 'calendar'}
        />
        <SideNavBar.Item
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
          elementRef={el => (inboxRef.current = el)}
          label={I18n.t('Inbox')}
          href="/conversations"
          selected={selectedNavItem === 'conversations'}
          themeOverride={navItemThemeOverride}
        />
        <SideNavBar.Item
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
          elementRef={el => (helpRef.current = el)}
          label={I18n.t('Help')}
          href="https://help.instructure.com/"
          onClick={event => {
            event.preventDefault()
            setActiveTray('help')
          }}
          selected={selectedNavItem === 'help'}
          themeOverride={navItemThemeOverride}
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
                setIsTrayOpen(false)
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
              setIsTrayOpen(false)
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
              {activeTray === 'help' && <HelpTray closeTray={() => setIsTrayOpen(false)} />}
            </React.Suspense>
          </div>
        </div>
      </Tray>
    </div>
  )
}

export default SideNav
