/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import I18n from 'i18n!student_context_trayStudentContextTray'
import Avatar from './Avatar'
import LastActivity from './LastActivity'
import MetricsList from './MetricsList'
import Rating from './Rating'
import SectionInfo from './SectionInfo'
import SubmissionProgressBars from './SubmissionProgressBars'
import MessageStudents from '@canvas/message-students-modal'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tray} from '@instructure/ui-tray'

const courseShape = PropTypes.shape({
  permissions: PropTypes.shape({}).isRequired,
  submissionsConnection: PropTypes.shape({
    edges: PropTypes.arrayOf(PropTypes.shape({}))
  }).isRequired
})
const userShape = PropTypes.shape({
  enrollments: PropTypes.arrayOf(PropTypes.object).isRequired
})
const dataShape = PropTypes.shape({
  loading: PropTypes.bool.isRequired,
  course: courseShape,
  user: userShape
})

export default class StudentContextTray extends React.Component {
  static propTypes = {
    courseId: PropTypes.string.isRequired,
    studentId: PropTypes.string.isRequired,
    returnFocusTo: PropTypes.func.isRequired,
    data: dataShape.isRequired,
    externalTools: PropTypes.arrayOf(
      PropTypes.shape({
        base_url: PropTypes.string.isRequired,
        title: PropTypes.string.isRequired
      })
    )
  }

  static renderQuickLink(key, label, srLabel, url, showIf) {
    return showIf() ? (
      <div className="StudentContextTray-QuickLinks__Link" key={key}>
        <Button href={url} variant="ghost" size="small" fluidWidth aria-label={srLabel}>
          <span className="StudentContextTray-QuickLinks__Link-text">{label}</span>
        </Button>
      </div>
    ) : null
  }

  constructor(props) {
    super(props)
    this.state = {
      isOpen: true,
      messageFormOpen: false
    }
  }

  /**
   * Lifecycle
   */

  componentWillReceiveProps(nextProps) {
    if (!this.state.isOpen) {
      this.setState({isOpen: true})
    }
  }

  /**
   * Handlers
   */

  handleRequestClose = e => {
    e.preventDefault()
    this.setState({
      isOpen: false
    })
    if (this.props.returnFocusTo) {
      const focusableItems = this.props.returnFocusTo()
      // Because of the way native focus calls return undefined, all focus
      // objects should be wrapped in something that will return truthy like
      // jQuery wrappers do... and it should be able to check visibility like a
      // jQuery wrapper... so just use jQuery.
      focusableItems.some($itemToFocus => $itemToFocus.is(':visible') && $itemToFocus.focus())
    }
  }

  handleMessageButtonClick = e => {
    e.preventDefault()
    this.setState({
      messageFormOpen: true
    })
  }

  handleMessageFormClose = e => {
    if (e) {
      e.preventDefault()
    }

    this.setState(
      {
        messageFormOpen: false
      },
      () => {
        this.messageStudentsButton.focus()
      }
    )
  }

  /**
   * Renderers
   */

  renderQuickLinks(user, course) {
    return user.short_name &&
      (course.permissions.manage_grades ||
        course.permissions.view_all_grades ||
        course.permissions.view_analytics) ? (
      <section className="StudentContextTray__Section StudentContextTray-QuickLinks">
        {StudentContextTray.renderQuickLink(
          'grades',
          I18n.t('Grades'),
          I18n.t('View grades for %{name}', {name: user.short_name}),
          `/courses/${this.props.courseId}/grades/${this.props.studentId}`,

          () => course.permissions.manage_grades || course.permissions.view_all_grades
        )}
        {
          // only include analytics 1 link if analytics 2 is not among the external tool links
          this.props.externalTools &&
          this.props.externalTools.some(t => t.tool_id == 'fd75124a-140e-470f-944c-114d2d93bb40')
            ? null
            : StudentContextTray.renderQuickLink(
                'analytics',
                I18n.t('Analytics'),
                I18n.t('View analytics for %{name}', {name: user.short_name}),
                `/courses/${this.props.courseId}/analytics/users/${this.props.studentId}`,
                () => course.permissions.view_analytics && user.analytics
              )
        }
        {this.props.externalTools
          ? this.props.externalTools.map((tool, i) => {
              return StudentContextTray.renderQuickLink(
                `tool${i}`,
                tool.title,
                tool.title,
                `${tool.base_url}&student_id=${this.props.studentId}`,
                () => true
              )
            })
          : null}
      </section>
    ) : null
  }

  render() {
    const {
      data: {loading, course, user}
    } = this.props

    return (
      <div>
        {this.state.messageFormOpen ? (
          <MessageStudents
            contextCode={`course_${course._id}`}
            onRequestClose={this.handleMessageFormClose}
            open={this.state.messageFormOpen}
            recipients={[
              {
                id: user._id,
                displayName: user.short_name
              }
            ]}
            title="Send a message"
          />
        ) : null}

        <Tray
          label={I18n.t('Student Details')}
          open={this.state.isOpen}
          onDismiss={this.handleRequestClose}
          placement="end"
        >
          <CloseButton placement="start" onClick={this.handleRequestClose}>
            {I18n.t('Close')}
          </CloseButton>
          <aside
            className={
              user && user.avatar_url
                ? 'StudentContextTray StudentContextTray--withAvatar'
                : 'StudentContextTray'
            }
          >
            {loading ? (
              <div className="StudentContextTray__Spinner">
                <Spinner renderTitle={I18n.t('Loading')} size="large" />
              </div>
            ) : (
              <div>
                <header className="StudentContextTray-Header">
                  <Avatar
                    user={user}
                    canMasquerade={course.permissions && course.permissions.become_user}
                    courseId={this.props.courseId}
                  />

                  <div className="StudentContextTray-Header__Layout">
                    <div className="StudentContextTray-Header__Content">
                      {user.short_name ? (
                        <div className="StudentContextTray-Header__Name">
                          <Heading level="h3" as="h2">
                            <Button
                              variant="link"
                              size="large"
                              fluidWidth
                              href={`/courses/${this.props.courseId}/users/${this.props.studentId}`}
                              aria-label={I18n.t("Go to %{name}'s profile", {
                                name:
                                  user.pronouns != null
                                    ? `${user.short_name} ${user.pronouns}`
                                    : user.short_name
                              })}
                              theme={{largePadding: '0', largeHeight: 'normal'}}
                            >
                              {user.short_name} {user.pronouns ? <i>{user.pronouns}</i> : ''}
                            </Button>
                          </Heading>
                        </div>
                      ) : null}
                      <div className="StudentContextTray-Header__CourseName">
                        <Text size="medium" as="div" lineHeight="condensed">
                          {course.name}
                        </Text>
                      </div>
                      <Text size="x-small" color="secondary" as="div">
                        <SectionInfo user={user} />
                      </Text>
                      <Text size="x-small" color="secondary" as="div">
                        <LastActivity user={user} />
                      </Text>
                    </div>
                    {course.permissions.send_messages &&
                    user.enrollments.some(e => e.state == 'active') ? (
                      <div className="StudentContextTray-Header__Actions">
                        <Button
                          ref={b => (this.messageStudentsButton = b)}
                          variant="icon"
                          size="small"
                          onClick={this.handleMessageButtonClick}
                        >
                          <ScreenReaderContent>
                            {I18n.t('Send a message to %{student}', {student: user.short_name})}
                          </ScreenReaderContent>

                          {/* Note: replace with instructure-icon */}
                          <i className="icon-email" aria-hidden="true" />
                        </Button>
                      </div>
                    ) : null}
                  </div>
                </header>
                {this.renderQuickLinks(user, course)}
                <MetricsList user={user} analytics={user.analytics} />
                <SubmissionProgressBars
                  submissions={course.submissionsConnection.edges.map(n => n.submission)}
                />

                {user.analytics ? (
                  <section className="StudentContextTray__Section StudentContextTray-Ratings">
                    <Heading level="h4" as="h3" border="bottom">
                      {I18n.t('Activity Compared to Class')}
                    </Heading>
                    <div className="StudentContextTray-Ratings__Layout">
                      <Rating
                        metric={user.analytics.participations}
                        label={I18n.t('Participation')}
                      />
                      <Rating metric={user.analytics.page_views} label={I18n.t('Page Views')} />
                    </div>
                  </section>
                ) : null}
              </div>
            )}
          </aside>
        </Tray>
      </div>
    )
  }
}
