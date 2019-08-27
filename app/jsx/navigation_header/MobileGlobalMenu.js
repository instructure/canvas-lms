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

import React from 'react'
import {shape, object, func, string, oneOfType, arrayOf, node} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {View, Flex, FlexItem} from '@instructure/ui-layout'
import {Heading, List, ListItem, Spinner, Text, Avatar, Badge} from '@instructure/ui-elements'
import {Button} from '@instructure/ui-buttons'
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
  IconCalendarMonthLine
} from '@instructure/ui-icons'
import I18n from 'i18n!MobileNavigation'
import HelpDialog from '../help_dialog/HelpDialog'
import LogoutButton from './LogoutButton'

function ActiveText({children, url}) {
  return window.location.pathname.startsWith(url) ? <Text weight="bold">{children}</Text> : children
}
ActiveText.propTypes = {
  url: string.isRequired,
  children: oneOfType([arrayOf(node), node]).isRequired
}

export default class MobileGlobalMenu extends React.Component {
  state = {
    externalTools: [],
    showGroups: false
  }

  static propTypes = {
    current_user: shape({
      display_name: string,
      avatar_image_url: string
    }),
    DesktopNavComponent: shape({
      ensureLoaded: func.isRequired,
      state: object.isRequired
    }).isRequired,
    onDismiss: func.isRequired
  }

  static defaultProps = {
    current_user: ENV.current_user
  }

  componentWillMount() {
    // this is all the stuff that relies on the DOM of the desktop global nav
    const showGroups = !!document.getElementById('global_nav_groups_link')

    const externalTools = [...document.querySelectorAll('.globalNavExternalTool')].map(el => {
      const svg = el.querySelector('svg')
      return {
        href: el.querySelector('a').getAttribute('href'),
        isActive: el.classList.contains('ic-app-header__menu-list-item--active'),
        label: el.querySelector('.menu-item__text').innerText,
        ...(svg ? {svgPath: svg.innerHTML} : {imgSrc: el.querySelector('img').getAttribute('src')})
      }
    })
    this.setState({externalTools, showGroups})
  }

  render() {
    const ensureLoaded = type => (_e, isExpanded) => {
      if (isExpanded) this.props.DesktopNavComponent.ensureLoaded(type)
    }

    return (
      <View
        display="block"
        height="100%"
        width="100%"
        textAlign="start"
        padding="medium large medium medium"
      >
        <Flex direction="row-reverse" margin="0 0 large 0">
          <FlexItem>
            <Button variant="icon" icon={IconXLine} onClick={this.props.onDismiss}>
              <ScreenReaderContent>Close</ScreenReaderContent>
            </Button>
          </FlexItem>
          <FlexItem grow shrink>
            <Heading>
              <a className="ic-brand-mobile-global-nav-logo" href="/">
                <span className="screenreader-only">{I18n.t('My Dashboard')}</span>
              </a>
            </Heading>
          </FlexItem>
        </Flex>
        <List variant="unstyled" itemSpacing="medium">
          <ListItem>
            <Button variant="link" href="/" size="small" fluidWidth>
              <Flex>
                <FlexItem width="3rem">
                  <IconDashboardLine inline={false} size="small" />
                </FlexItem>
                <FlexItem>
                  <Text size="medium">{I18n.t('Dashboard')}</Text>
                </FlexItem>
              </Flex>
            </Button>
          </ListItem>
          <ListItem>
            {this.props.current_user && Object.keys(this.props.current_user).length ? (
              <ToggleDetails
                iconPosition="end"
                fluidWidth
                onToggle={ensureLoaded('profile')}
                summary={
                  <Flex padding="xx-small small">
                    <FlexItem width="3rem">
                      <Avatar
                        name={this.props.current_user.display_name}
                        src={this.props.current_user.avatar_image_url}
                        size="x-small"
                      />
                    </FlexItem>
                    <FlexItem>
                      <Text color="brand">{I18n.t('Account')}</Text>
                    </FlexItem>
                  </Flex>
                }
              >
                <List variant="unstyled" itemSpacing="small" margin="0 0 0 x-large">
                  {this.props.DesktopNavComponent.state.profileAreLoaded ? (
                    this.props.DesktopNavComponent.state.profile.map(tab => (
                      <ListItem key={tab.id}>
                        <Button variant="link" fluidWidth href={tab.html_url}>
                          <ActiveText url={tab.html_url}>{tab.label}</ActiveText>
                        </Button>
                      </ListItem>
                    ))
                  ) : (
                    <ListItem>
                      <Spinner margin="auto" size="small" title={I18n.t('Loading')} />
                    </ListItem>
                  )}
                  <ListItem>
                    <LogoutButton variant="link" fluidWidth />
                  </ListItem>
                </List>
              </ToggleDetails>
            ) : (
              <Button variant="link" href="/login" fluidWidth>
                <Flex>
                  <FlexItem width="3rem">
                    <IconLockLine inline={false} size="small" />
                  </FlexItem>
                  <FlexItem>
                    <Text size="medium">{I18n.t('Login')}</Text>
                  </FlexItem>
                </Flex>
              </Button>
            )}
          </ListItem>

          {window.ENV.current_user_roles && window.ENV.current_user_roles.includes('admin') && (
            <ListItem>
              <ToggleDetails
                iconPosition="end"
                fluidWidth
                onToggle={ensureLoaded('accounts')}
                summary={
                  <Flex padding="xx-small small">
                    <FlexItem width="3rem">
                      <IconAdminLine inline={false} size="small" color="brand" />
                    </FlexItem>
                    <FlexItem>
                      <Text color="brand">{I18n.t('Admin')}</Text>
                    </FlexItem>
                  </Flex>
                }
              >
                <List variant="unstyled" itemSpacing="small" margin="0 0 0 x-large">
                  {this.props.DesktopNavComponent.state.accountsAreLoaded ? (
                    this.props.DesktopNavComponent.state.accounts
                      .map(account => (
                        <ListItem key={account.id}>
                          <Button variant="link" fluidWidth href={`/accounts/${account.id}`}>
                            <ActiveText url={`/accounts/${account.id}`}>{account.name}</ActiveText>
                          </Button>
                        </ListItem>
                      ))
                      .concat([
                        <ListItem key="all">
                          <Button variant="link" fluidWidth href="/accounts">
                            {I18n.t('All Accounts')}
                          </Button>
                        </ListItem>
                      ])
                  ) : (
                    <ListItem>
                      <Spinner size="small" title={I18n.t('Loading')} />
                    </ListItem>
                  )}
                </List>
              </ToggleDetails>
            </ListItem>
          )}
          <ListItem>
            <ToggleDetails
              iconPosition="end"
              fluidWidth
              onToggle={ensureLoaded('courses')}
              summary={
                <Flex padding="xx-small small">
                  <FlexItem width="3rem">
                    <IconCoursesLine inline={false} size="small" color="brand" />
                  </FlexItem>
                  <FlexItem>
                    <Text color="brand">{I18n.t('Courses')}</Text>
                  </FlexItem>
                </Flex>
              }
            >
              <List variant="unstyled" itemSpacing="small" margin="0 0 0 x-large">
                {this.props.DesktopNavComponent.state.coursesAreLoaded ? (
                  this.props.DesktopNavComponent.state.courses
                    .map(course => (
                      <ListItem key={course.id}>
                        <Button variant="link" fluidWidth href={`/courses/${course.id}`}>
                          <ActiveText url={`/courses/${course.id}`}>
                            {course.name}
                            {course.enrollment_term_id > 1 && (
                              <Text as="div" size="x-small" weight="light">
                                {course.term.name}
                              </Text>
                            )}
                          </ActiveText>
                        </Button>
                      </ListItem>
                    ))
                    .concat([
                      <ListItem key="all">
                        <Button variant="link" fluidWidth href="/courses">
                          {I18n.t('All Courses')}
                        </Button>
                      </ListItem>
                    ])
                ) : (
                  <ListItem>
                    <Spinner size="small" title={I18n.t('Loading')} />
                  </ListItem>
                )}
              </List>
            </ToggleDetails>
          </ListItem>
          {this.state.showGroups && (
            <ListItem>
              <ToggleDetails
                iconPosition="end"
                fluidWidth
                onToggle={ensureLoaded('groups')}
                summary={
                  <Flex padding="xx-small small">
                    <FlexItem width="3rem">
                      <IconGroupLine inline={false} size="small" color="brand" />
                    </FlexItem>
                    <FlexItem>
                      <Text color="brand">{I18n.t('Groups')}</Text>
                    </FlexItem>
                  </Flex>
                }
              >
                <List variant="unstyled" itemSpacing="small" margin="0 0 0 x-large">
                  {this.props.DesktopNavComponent.state.groupsAreLoaded ? (
                    this.props.DesktopNavComponent.state.groups
                      .map(group => (
                        <ListItem key={group.id}>
                          <Button
                            variant="link"
                            fluidWidth
                            margin="0 0 0 xx-small"
                            href={`/groups/${group.id}`}
                          >
                            <ActiveText url={`/groups/${group.id}`}>{group.name}</ActiveText>
                          </Button>
                        </ListItem>
                      ))
                      .concat([
                        <ListItem key="all">
                          <Button variant="link" fluidWidth margin="0 0 0 xx-small" href="/groups">
                            {I18n.t('All Groups')}
                          </Button>
                        </ListItem>
                      ])
                  ) : (
                    <ListItem>
                      <Spinner size="small" title={I18n.t('Loading')} />
                    </ListItem>
                  )}
                </List>
              </ToggleDetails>
            </ListItem>
          )}
          <ListItem>
            <Button variant="link" href="/calendar" size="small" fluidWidth>
              <Flex>
                <FlexItem width="3rem">
                  <IconCalendarMonthLine inline={false} size="small" />
                </FlexItem>
                <FlexItem>
                  <Text size="medium">{I18n.t('Calendar')}</Text>
                </FlexItem>
              </Flex>
            </Button>
          </ListItem>
          <ListItem>
            <Button variant="link" href="/inbox" size="small" fluidWidth>
              <Flex>
                <FlexItem width="3rem">
                  <IconInboxLine inline={false} size="small" />
                </FlexItem>
                <FlexItem>
                  <Text size="medium">{I18n.t('Inbox')}</Text>
                  {!!this.props.DesktopNavComponent.state.unread_count && (
                    <Badge
                      standalone
                      margin="0 small"
                      count={this.props.DesktopNavComponent.state.unread_count}
                    />
                  )}
                </FlexItem>
              </Flex>
            </Button>
          </ListItem>
          {this.state.externalTools.map(tool => (
            <ListItem key={tool.href}>
              <Button variant="link" href={tool.href} size="small" fluidWidth>
                <Flex>
                  <FlexItem width="3rem">
                    {tool.svgPath ? (
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
                  </FlexItem>
                  <FlexItem>
                    <Text size="medium">{tool.label}</Text>
                  </FlexItem>
                </Flex>
              </Button>
            </ListItem>
          ))}

          {true /* TODO: put a check for if we should show help */ && (
            <ListItem>
              <ToggleDetails
                iconPosition="end"
                fluidWidth
                onToggle={ensureLoaded('help')}
                summary={
                  <Flex padding="xx-small small">
                    <FlexItem width="3rem">
                      <IconQuestionLine inline={false} size="small" color="brand" />
                    </FlexItem>
                    <FlexItem>
                      <Text color="brand">{window.ENV.help_link_name || I18n.t('Help')}</Text>
                    </FlexItem>
                  </Flex>
                }
              >
                <View as="div" margin="0 0 0 xx-large">
                  <HelpDialog
                    links={this.props.DesktopNavComponent.state.help}
                    hasLoaded={this.props.DesktopNavComponent.state.helpAreLoaded}
                    onFormSubmit={this.props.onDismiss}
                  />
                </View>
              </ToggleDetails>
            </ListItem>
          )}
        </List>
      </View>
    )
  }
}
