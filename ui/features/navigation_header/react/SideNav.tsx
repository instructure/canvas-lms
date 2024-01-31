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

import React, {useEffect, useLayoutEffect, useRef, useState} from 'react'
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
import {getActiveItem, getTrayLabel, getTrayPortal} from './utils'
import type {ActiveTray, ExternalTool} from './utils'
import {getSetting, setSetting} from '@canvas/settings-query/react/settingsQuery'

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

const SideNav = ({externalTools = []}: {externalTools?: ExternalTool[]}) => {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const [activeTray, setActiveTray] = useState<ActiveTray | null>(null)
  const [selectedNavItem, setSelectedNavItem] = useState<ActiveTray | ''>(defaultActiveItem)
  const sideNavRef = useRef<HTMLDivElement | null>(null)
  const logoRef = useRef<Element | null>(null)
  const accountRef = useRef<Element | null>(null)
  const adminRef = useRef<Element | null>(null)
  const dashboardRef = useRef<Element | null>(null)
  const coursesRef = useRef<Element | null>(null)
  const calendarRef = useRef<Element | null>(null)
  const inboxRef = useRef<Element | null>(null)
  const historyRef = useRef<Element | null>(null)
  const externalTool = useRef<Element | null>(null)
  const helpRef = useRef<Element | null>(null)

  // after tray is closed, eventually set activeTray to null
  // we don't do this immediately in order to maintain animation of closing tray
  useEffect(() => {
    if (!isTrayOpen) {
      setTimeout(() => setActiveTray(null), 100)
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
    iconSize: '1.5675rem',
    iconColor: 'white',
    contentPadding: '0.1rem',
    backgroundColor: 'transparent',
    hoverBackgroundColor: 'transparent',
    fontWeight: 400,
    linkTextDecoration: 'inherit',
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

  useLayoutEffect(() => {
    /** New SideNav CSS  */
    const sideNavTrays = [
      document.querySelector('#admin-tray'),
      document.querySelector('#dashboard-tray'),
      document.querySelector('#courses-tray'),
      document.querySelector('#calendar-tray'),
      document.querySelector('#inbox-tray'),
      document.querySelector('#history-tray'),
      document.querySelector('#external-tool-tray'),
      document.querySelector('#help-tray'),
    ]
    if (Array.isArray(sideNavTrays))
      sideNavTrays.forEach(sideNavTray => sideNavTray?.classList.add('ic-sidenav-tray'))

    const externalToolsSvgImg = ['ic-svg-external-tool', 'ic-img-external-tool']

    if (Array.isArray(externalToolsSvgImg))
      externalToolsSvgImg.forEach(svgImgClassName =>
        document.querySelector('#external-tool-tray')?.classList.add(svgImgClassName)
      )

    document.querySelector('#user-tray')?.classList.add('ic-user-tray')
    document.querySelector('#canvas-logo')?.classList.add('ic-canvas-logo')
    document.querySelector('#brand-logo')?.classList.add('ic-brand-logo')
    document.querySelector('#user-avatar')?.classList.add('ic-user-avatar')

    const collapseDiv = document.querySelectorAll('[aria-label="Main navigation"]')[0]
      .childNodes[1] as HTMLElement
    const collapseButton = collapseDiv.childNodes[0] as HTMLElement
    collapseDiv.classList.add('ic-collapse-div')
    collapseButton.classList.add('ic-collapse-button')
    collapseButton.id = 'sidenav-toggle'

    if (collapseGlobalNav) document.body.classList.remove('primary-nav-expanded')
    else document.body.classList.add('primary-nav-expanded')

    /** New SideNav CSS  */
  }, [collapseGlobalNav])

  return (
    <div
      ref={sideNavRef}
      style={{width: '100%', height: '100vh'}}
      className="sidenav-container"
      data-testid="sidenav-container"
    >
      <style>{`
        ${
          !collapseGlobalNav
            ? `
        .sidenav-container a[logo-tray="true"] {
          height: 85px !important;
        }
        .sidenav-container a[account-tray="true"] {
          height: 72.59px !important;
        }`
            : ''
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
          elementRef={el => (logoRef.current = el)}
          icon={
            !logoUrl ? (
              <div id="canvas-logo">
                <IconCanvasLogoSolid data-testid="sidenav-canvas-logo" />
              </div>
            ) : (
              <div id="brand-logo">
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
          minimized={collapseGlobalNav}
          data-testid="sidenav-header-logo"
        />
        <SideNavBar.Item
          id="user-tray"
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
                size="x-small"
                src={window.ENV.current_user.avatar_image_url}
                data-testid="sidenav-user-avatar"
                showBorder="always"
                frameBorder={4}
                themeOverride={{
                  background: 'transparent',
                  borderColor: '#ffffff',
                  borderWidthSmall: '0.2em',
                  borderWidthMedium: '0.2rem',
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
          minimized={collapseGlobalNav}
        />
        <SideNavBar.Item
          id="admin-tray"
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
          minimized={collapseGlobalNav}
        />
        <SideNavBar.Item
          id="dashboard-tray"
          elementRef={el => (dashboardRef.current = el)}
          icon={isK5User ? <IconHomeLine data-testid="K5HomeIcon" /> : <IconDashboardLine />}
          label={isK5User ? I18n.t('Home') : I18n.t('Dashboard')}
          href="/"
          selected={selectedNavItem === 'dashboard'}
          themeOverride={navItemThemeOverride}
          minimized={collapseGlobalNav}
        />
        <SideNavBar.Item
          id="courses-tray"
          // id={selectedNavItem === 'courses' ? 'active-courses' : ''}
          elementRef={el => (coursesRef.current = el)}
          icon={<IconCoursesLine />}
          label={isK5User ? I18n.t('Subjects') : I18n.t('Courses')}
          href="/courses"
          onClick={event => {
            event.preventDefault()
            setActiveTray('courses')
          }}
          selected={selectedNavItem === 'courses'}
          themeOverride={navItemThemeOverride}
          minimized={collapseGlobalNav}
        />
        <SideNavBar.Item
          id="calendar-tray"
          elementRef={el => (calendarRef.current = el)}
          icon={<IconCalendarMonthLine />}
          label={I18n.t('Calendar')}
          href="/calendar"
          selected={selectedNavItem === 'calendar'}
          themeOverride={navItemThemeOverride}
          minimized={collapseGlobalNav}
        />
        <SideNavBar.Item
          id="inbox-tray"
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
          minimized={collapseGlobalNav}
        />
        <SideNavBar.Item
          id="history-tray"
          elementRef={el => (historyRef.current = el)}
          icon={<IconClockLine />}
          label={I18n.t('History')}
          href={window.ENV.page_view_update_url}
          selected={selectedNavItem === 'history'}
          themeOverride={navItemThemeOverride}
          minimized={collapseGlobalNav}
        />
        {externalTools &&
          externalTools.map(tool => (
            <SideNavBar.Item
              key={tool.href}
              id="external-tool-tray"
              elementRef={el => (externalTool.current = el)}
              icon={
                'svgPath' in tool ? (
                  <svg
                    id="svg-external-tool"
                    version="1.1"
                    xmlns="http://www.w3.org/2000/svg"
                    xmlnsXlink="http://www.w3.org/1999/xlink"
                    viewBox="0 0 26 26"
                    dangerouslySetInnerHTML={{__html: tool.svgPath ?? ''}}
                    width="26px"
                    height="26px"
                    aria-hidden="true"
                    role="presentation"
                    focusable="false"
                    style={{fill: 'currentColor', fontSize: 26}}
                  />
                ) : (
                  <img id="img-external-tool" width="26px" height="26px" src={tool.imgSrc} alt="" />
                )
              }
              label={tool.label}
              href={tool.href?.toString()}
              selected={tool.isActive}
              themeOverride={navItemThemeOverride}
              minimized={collapseGlobalNav}
            />
          ))}
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
          elementRef={el => (helpRef.current = el)}
          label={I18n.t('Help')}
          href="https://help.instructure.com/"
          onClick={event => {
            event.preventDefault()
            setActiveTray('help')
          }}
          selected={selectedNavItem === 'help'}
          themeOverride={navItemThemeOverride}
          minimized={collapseGlobalNav}
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
