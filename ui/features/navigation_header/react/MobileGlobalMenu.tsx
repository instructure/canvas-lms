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

import React, {useState, useEffect} from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Badge} from '@instructure/ui-badge'
import {Avatar} from '@instructure/ui-avatar'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {IconButton} from '@instructure/ui-buttons'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {
  IconXLine,
  IconAdminLine,
  IconCoursesLine,
  IconGroupLine,
  IconDashboardLine,
  IconLockLine,
  IconQuestionLine,
  IconInboxLine,
  IconCalendarMonthLine,
  IconClockLine,
  IconHomeLine,
} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import HelpDialog from './HelpDialog/index'
import LogoutButton from './LogoutButton'
import HighContrastModeToggle from './trays/HighContrastModeToggle'
import HistoryList from './HistoryList'
import {Link} from '@instructure/ui-link'
import type {AccessibleGroup, Course, HelpLink, HistoryEntry, ProfileTab} from '../../../api.d'

const I18n = useI18nScope('MobileGlobalMenu')

type ActiveTextProps = {
  url: string
  children: React.ReactNode
}

const ActiveText: React.FC<ActiveTextProps> = ({children, url}) => {
  return window.location.pathname.startsWith(url) ? (
    <Text weight="bold">{children}</Text>
  ) : (
    <>{children}</>
  )
}

type CommonProperties = {
  href: string | null | undefined
  isActive: boolean
  label: string
}

type SvgTool = CommonProperties & {svgPath: string}
type ImgTool = CommonProperties & {imgSrc: string}

type ExternalTool = SvgTool | ImgTool

type Props = {
  current_user: {
    display_name: string
    avatar_image_url: string
  }
  DesktopNavComponent: {
    ensureLoaded: (type: string) => void
    state: {
      courses: Course[]
      profileAreLoaded: boolean
      profile: ProfileTab[]
      accountsAreLoaded: boolean
      accounts: {id: string; name: string}[]
      coursesAreLoaded: boolean
      groupsAreLoaded: boolean
      groups: AccessibleGroup[]
      historyAreLoaded: boolean
      history: HistoryEntry[]
      helpAreLoaded: boolean
      help: HelpLink[]
      unreadInboxCount: number
    }
  }
  onDismiss: () => void
  k5User: boolean
  isStudent: boolean
}

export default function MobileGlobalMenu(props: Props) {
  const [externalTools, setExternalTools] = useState<ExternalTool[]>([])
  const [showGroups, setShowGroups] = useState(false)

  useEffect(() => {
    // this is all the stuff that relies on the DOM of the desktop global nav
    const newExternalTools: ExternalTool[] = Array.from(
      document.querySelectorAll('.globalNavExternalTool')
    ).map(el => {
      const svg = el.querySelector('svg')
      return {
        href: el.querySelector('a')?.getAttribute('href'),
        isActive: el.classList.contains('ic-app-header__menu-list-item--active'),
        label: (el.querySelector('.menu-item__text') as HTMLDivElement)?.innerText || '',
        ...(svg
          ? {svgPath: svg.innerHTML}
          : {imgSrc: (el.querySelector('img') as HTMLImageElement)?.getAttribute('src') || ''}),
      }
    })
    setExternalTools(newExternalTools)
    setShowGroups(Boolean(document.getElementById('global_nav_groups_link')))
  }, [])

  const courses =
    props.k5User && props.isStudent
      ? props.DesktopNavComponent.state.courses.filter((c: Course) => !c.homeroom_course)
      : props.DesktopNavComponent.state.courses

  return (
    <View
      display="block"
      height="100%"
      width="100%"
      textAlign="start"
      padding="medium large medium medium"
    >
      <Flex direction="row-reverse" margin="0 0 large 0">
        <Flex.Item>
          <IconButton
            renderIcon={IconXLine}
            withBackground={false}
            withBorder={false}
            onClick={props.onDismiss}
            screenReaderLabel="Close"
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Heading>
            <a className="ic-brand-mobile-global-nav-logo" href="/">
              <span className="screenreader-only">
                {props.k5User ? I18n.t('Home') : I18n.t('My Dashboard')}
              </span>
            </a>
          </Heading>
        </Flex.Item>
      </Flex>
      <List isUnstyled={true} itemSpacing="medium">
        <List.Item>
          <Link href="/" isWithinText={false} display="block">
            <Flex>
              <Flex.Item width="3rem">
                {props.k5User ? (
                  <IconHomeLine inline={false} size="small" />
                ) : (
                  <IconDashboardLine inline={false} size="small" />
                )}
              </Flex.Item>
              <Flex.Item>
                <Text size="medium">{props.k5User ? I18n.t('Home') : I18n.t('Dashboard')}</Text>
              </Flex.Item>
            </Flex>
          </Link>
        </List.Item>
        <List.Item>
          {props.current_user && Object.keys(props.current_user).length > 0 ? (
            <ToggleDetails
              iconPosition="end"
              fluidWidth={true}
              onToggle={(_e, isExpanded: boolean) => {
                if (isExpanded) {
                  props.DesktopNavComponent.ensureLoaded('profile')
                }
              }}
              summary={
                <Flex padding="xx-small small">
                  <Flex.Item width="3rem">
                    <Avatar
                      name={props.current_user.display_name}
                      src={props.current_user.avatar_image_url}
                      size="x-small"
                      data-fs-exclude={true}
                    />
                  </Flex.Item>
                  <Flex.Item>
                    <Text color="brand">{I18n.t('Account')}</Text>
                  </Flex.Item>
                </Flex>
              }
            >
              <List isUnstyled={true} itemSpacing="small" margin="0 0 0 x-large">
                {props.DesktopNavComponent.state.profileAreLoaded ? (
                  props.DesktopNavComponent.state.profile.map(tab => (
                    <List.Item key={tab.id}>
                      <Link href={tab.html_url} isWithinText={false} display="block">
                        <ActiveText url={tab.html_url}>{tab.label}</ActiveText>
                      </Link>
                    </List.Item>
                  ))
                ) : (
                  <List.Item>
                    <Spinner margin="auto" size="small" renderTitle={I18n.t('Loading')} />
                  </List.Item>
                )}
                <List.Item>
                  <LogoutButton />
                </List.Item>
                <List.Item>
                  <HighContrastModeToggle isMobile={true} />
                </List.Item>
              </List>
            </ToggleDetails>
          ) : (
            <Link href="/login" isWithinText={false} display="block">
              <Flex>
                <Flex.Item width="3rem">
                  <IconLockLine inline={false} size="small" />
                </Flex.Item>
                <Flex.Item>
                  <Text size="medium">{I18n.t('Login')}</Text>
                </Flex.Item>
              </Flex>
            </Link>
          )}
        </List.Item>

        {window.ENV.current_user_roles && window.ENV.current_user_roles.includes('admin') && (
          <List.Item>
            <ToggleDetails
              iconPosition="end"
              fluidWidth={true}
              onToggle={(_e, isExpanded: boolean) => {
                if (isExpanded) {
                  props.DesktopNavComponent.ensureLoaded('accounts')
                }
              }}
              summary={
                <Flex padding="xx-small small">
                  <Flex.Item width="3rem">
                    <IconAdminLine inline={false} size="small" color="brand" />
                  </Flex.Item>
                  <Flex.Item>
                    <Text color="brand">{I18n.t('Admin')}</Text>
                  </Flex.Item>
                </Flex>
              }
            >
              <List isUnstyled={true} itemSpacing="small" margin="0 0 0 x-large">
                {props.DesktopNavComponent.state.accountsAreLoaded ? (
                  props.DesktopNavComponent.state.accounts
                    .map(account => (
                      <List.Item key={account.id}>
                        <Link href={`/accounts/${account.id}`} isWithinText={false} display="block">
                          <ActiveText url={`/accounts/${account.id}`}>{account.name}</ActiveText>
                        </Link>
                      </List.Item>
                    ))
                    .concat([
                      <List.Item key="all">
                        <Link href="/accounts" isWithinText={false} display="block">
                          {I18n.t('All Accounts')}
                        </Link>
                      </List.Item>,
                    ])
                ) : (
                  <List.Item>
                    <Spinner size="small" renderTitle={I18n.t('Loading')} />
                  </List.Item>
                )}
              </List>
            </ToggleDetails>
          </List.Item>
        )}
        <List.Item>
          <ToggleDetails
            iconPosition="end"
            fluidWidth={true}
            onToggle={(_e, isExpanded: boolean) => {
              if (isExpanded) {
                props.DesktopNavComponent.ensureLoaded('courses')
              }
            }}
            summary={
              <Flex padding="xx-small small">
                <Flex.Item width="3rem">
                  <IconCoursesLine inline={false} size="small" color="brand" />
                </Flex.Item>
                <Flex.Item>
                  <Text color="brand">{props.k5User ? I18n.t('Subjects') : I18n.t('Courses')}</Text>
                </Flex.Item>
              </Flex>
            }
          >
            <List isUnstyled={true} itemSpacing="small" margin="0 0 0 x-large">
              {props.DesktopNavComponent.state.coursesAreLoaded ? (
                courses
                  .map(course => (
                    <List.Item key={course.id}>
                      <Link href={`/courses/${course.id}`} isWithinText={false} display="block">
                        <ActiveText url={`/courses/${course.id}`}>
                          {course.name}
                          {course.enrollment_term_id > 1 && (
                            <Text as="div" size="x-small" weight="light">
                              {course.term.name}
                            </Text>
                          )}
                        </ActiveText>
                      </Link>
                    </List.Item>
                  ))
                  .concat([
                    <List.Item key="all">
                      <Link
                        href="/courses"
                        isWithinText={false}
                        display="block"
                        // @ts-expect-error
                        textAlign="start"
                      >
                        {props.k5User ? I18n.t('All Subjects') : I18n.t('All Courses')}
                      </Link>
                    </List.Item>,
                  ])
              ) : (
                <List.Item>
                  <Spinner size="small" renderTitle={I18n.t('Loading')} />
                </List.Item>
              )}
            </List>
          </ToggleDetails>
        </List.Item>
        {showGroups && (
          <List.Item>
            <ToggleDetails
              iconPosition="end"
              fluidWidth={true}
              onToggle={(_e, isExpanded: boolean) => {
                if (isExpanded) {
                  props.DesktopNavComponent.ensureLoaded('groups')
                }
              }}
              summary={
                <Flex padding="xx-small small">
                  <Flex.Item width="3rem">
                    <IconGroupLine inline={false} size="small" color="brand" />
                  </Flex.Item>
                  <Flex.Item>
                    <Text color="brand">{I18n.t('Groups')}</Text>
                  </Flex.Item>
                </Flex>
              }
            >
              <List isUnstyled={true} itemSpacing="small" margin="0 0 0 x-large">
                {props.DesktopNavComponent.state.groupsAreLoaded ? (
                  props.DesktopNavComponent.state.groups
                    .map(group => (
                      <List.Item key={group.id}>
                        <Link
                          margin="0 0 0 xx-small"
                          href={`/groups/${group.id}`}
                          isWithinText={false}
                          display="block"
                        >
                          <ActiveText url={`/groups/${group.id}`}>{group.name}</ActiveText>
                        </Link>
                      </List.Item>
                    ))
                    .concat([
                      <List.Item key="all">
                        <Link
                          margin="0 0 0 xx-small"
                          href="/groups"
                          isWithinText={false}
                          display="block"
                        >
                          {I18n.t('All Groups')}
                        </Link>
                      </List.Item>,
                    ])
                ) : (
                  <List.Item>
                    <Spinner size="small" renderTitle={I18n.t('Loading')} />
                  </List.Item>
                )}
              </List>
            </ToggleDetails>
          </List.Item>
        )}
        <List.Item>
          <Link href="/calendar" isWithinText={false} display="block">
            <Flex>
              <Flex.Item width="3rem">
                <IconCalendarMonthLine inline={false} size="small" />
              </Flex.Item>
              <Flex.Item>
                <Text size="medium">{I18n.t('Calendar')}</Text>
              </Flex.Item>
            </Flex>
          </Link>
        </List.Item>
        <List.Item>
          <Link href="/inbox" isWithinText={false} display="block">
            <Flex>
              <Flex.Item width="3rem">
                <IconInboxLine inline={false} size="small" />
              </Flex.Item>
              <Flex.Item>
                <Text size="medium">{I18n.t('Inbox')}</Text>
                {!!props.DesktopNavComponent.state.unreadInboxCount && (
                  <Badge
                    standalone={true}
                    margin="0 small"
                    count={props.DesktopNavComponent.state.unreadInboxCount}
                  />
                )}
              </Flex.Item>
            </Flex>
          </Link>
        </List.Item>
        {externalTools.map(tool => (
          <List.Item key={tool.href}>
            <Link href={tool.href || ''} isWithinText={false} display="block">
              <Flex>
                <Flex.Item width="3rem">
                  {'svgPath' in tool ? (
                    <svg
                      version="1.1"
                      xmlns="http://www.w3.org/2000/svg"
                      xmlnsXlink="http://www.w3.org/1999/xlink"
                      viewBox="0 0 64 64"
                      dangerouslySetInnerHTML={{__html: tool.svgPath}}
                      width="1em"
                      height="1em"
                      aria-hidden="true"
                      role="presentation"
                      focusable="false"
                      style={{fill: 'currentColor', fontSize: 32}}
                    />
                  ) : (
                    <img width="1em" height="1em" src={tool.imgSrc} alt="" />
                  )}
                </Flex.Item>
                <Flex.Item>
                  <Text size="medium">{tool.label}</Text>
                </Flex.Item>
              </Flex>
            </Link>
          </List.Item>
        ))}

        <List.Item>
          <ToggleDetails
            iconPosition="end"
            fluidWidth={true}
            onToggle={(_e, isExpanded: boolean) => {
              if (isExpanded) {
                props.DesktopNavComponent.ensureLoaded('history')
              }
            }}
            summary={
              <Flex padding="xx-small small">
                <Flex.Item width="3rem">
                  <IconClockLine inline={false} size="small" color="brand" />
                </Flex.Item>
                <Flex.Item>
                  <Text color="brand">{I18n.t('History')}</Text>
                </Flex.Item>
              </Flex>
            }
          >
            <View as="div" margin="0 0 0 xx-large">
              <HistoryList
                history={props.DesktopNavComponent.state.history}
                hasLoaded={props.DesktopNavComponent.state.historyAreLoaded}
              />
            </View>
          </ToggleDetails>
        </List.Item>

        {true /* TODO: put a check for if we should show help */ && (
          <List.Item>
            <ToggleDetails
              iconPosition="end"
              fluidWidth={true}
              onToggle={(_e, isExpanded: boolean) => {
                if (isExpanded) {
                  props.DesktopNavComponent.ensureLoaded('help')
                }
              }}
              summary={
                <Flex padding="xx-small small">
                  <Flex.Item width="3rem">
                    <IconQuestionLine inline={false} size="small" color="brand" />
                  </Flex.Item>
                  <Flex.Item>
                    <Text color="brand">{window.ENV.help_link_name || I18n.t('Help')}</Text>
                  </Flex.Item>
                </Flex>
              }
            >
              <View as="div" margin="0 0 0 xx-large">
                <HelpDialog
                  links={props.DesktopNavComponent.state.help}
                  hasLoaded={props.DesktopNavComponent.state.helpAreLoaded}
                  onFormSubmit={props.onDismiss}
                />
              </View>
            </ToggleDetails>
          </List.Item>
        )}
      </List>
    </View>
  )
}

MobileGlobalMenu.defaultProps = {
  current_user: window.ENV.current_user,
  k5User: window.ENV.K5_USER,
  isStudent: window.ENV.current_user_roles?.every(role => role === 'student' || role === 'user'),
}
