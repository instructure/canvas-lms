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
import I18n from 'i18n!student_context_tray'
import FriendlyDatetime from 'jsx/shared/FriendlyDatetime'
import StudentCardStore from './StudentCardStore'
import Avatar from './Avatar'
import LastActivity from './LastActivity'
import MetricsList from './MetricsList'
import Rating from './Rating'
import SectionInfo from './SectionInfo'
import SubmissionProgressBars from './SubmissionProgressBars'
import MessageStudents from 'jsx/shared/MessageStudents'
import Heading from 'instructure-ui/lib/components/Heading'
import Button from 'instructure-ui/lib/components/Button'
import Link from 'instructure-ui/lib/components/Link'
import Typography from 'instructure-ui/lib/components/Typography'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import Spinner from 'instructure-ui/lib/components/Spinner'
import Tray from 'instructure-ui/lib/components/Tray'

export default class StudentContextTray extends React.Component {

    static propTypes = {
      courseId: PropTypes.string.isRequired,
      studentId: PropTypes.string.isRequired,
      store: PropTypes.instanceOf(StudentCardStore).isRequired,
      onClose: PropTypes.func.isRequired,
      returnFocusTo: PropTypes.func.isRequired
    }

    static renderQuickLink (label, srLabel, url, showIf) {
      return showIf() ? (
        <div className="StudentContextTray-QuickLinks__Link">
          <Button
            href={url}
            variant="ghost"
            size="small"
            fluidWidth
            aria-label={srLabel}
          >
            {label}
          </Button>
        </div>
      ) : null
    }

    constructor (props) {
      super(props)
      this.state = {
        analytics: {},
        course: {},
        isLoading: this.props.store.isLoading,
        isOpen: true,
        messageFormOpen: false,
        permissions: {},
        submissions: [],
        user: {}
      }
    }

    /**
     * Lifecycle
     */

    componentDidMount () {
      this.props.store.onChange = this.onChange
    }

    componentWillReceiveProps (nextProps) {
      if (nextProps.store !== this.props.store) {
        this.props.store.onChange = null
        nextProps.store.onChange = this.onChange
        const newState = {
          isLoading: true
        };
        if (!this.state.isOpen) {
          newState.isOpen = true
        }
        this.setState(newState)
      }
    }

    /**
     * Handlers
     */

    onChange = () => {
      const {store} = this.props;
      this.setState({
        analytics: store.state.analytics,
        course: store.state.course,
        isLoading: store.state.loading,
        permissions: store.state.permissions,
        submissions: store.state.submissions,
        user: store.state.user
      }, () => {
        if (!store.state.loading && this.state.isOpen) {
          if (this.closeButtonRef) {
            this.closeButtonRef.focus()
          }
        }
      })
    }

    getCloseButtonRef = (ref) => {
      this.closeButtonRef = ref
    }

    handleRequestClose = (e) => {
      e.preventDefault()
      this.setState({
        isOpen: false
      })
      if (this.props.returnFocusTo) {
        const focusableItems = this.props.returnFocusTo();
        // Because of the way native focus calls return undefined, all focus
        // objects should be wrapped in something that will return truthy like
        // jQuery wrappers do... and it should be able to check visibility like a
        // jQuery wrapper... so just use jQuery.
        focusableItems.some($itemToFocus => $itemToFocus.is(':visible') && $itemToFocus.focus())
      }
    }

    handleMessageButtonClick = (e) => {
      e.preventDefault()
      this.setState({
        messageFormOpen: true
      })
    }

    handleMessageFormClose = (e) => {
      e.preventDefault()
      this.setState({
        messageFormOpen: false
      }, () => {
        this.messageStudentsButton.focus()
      })
    }

    /**
     * Renderers
     */

    renderQuickLinks () {
      return (this.state.user.short_name && (
        this.state.permissions.manage_grades ||
        this.state.permissions.view_all_grades ||
        this.state.permissions.view_analytics
      )) ? (
        <section
          className="StudentContextTray__Section StudentContextTray-QuickLinks"
        >
          {StudentContextTray.renderQuickLink(
            I18n.t('Grades'),
            I18n.t('View grades for %{name}', { name: this.state.user.short_name }),
            `/courses/${this.props.courseId}/grades/${this.props.studentId}`,
            () =>
              this.state.permissions.manage_grades ||
              this.state.permissions.view_all_grades
          )}
          {StudentContextTray.renderQuickLink(
            I18n.t('Analytics'),
            I18n.t('View analytics for %{name}', { name: this.state.user.short_name }),
            `/courses/${this.props.courseId}/analytics/users/${this.props.studentId}`,
            () => (
              this.state.permissions.view_analytics && Object.keys(this.state.analytics).length > 0
            )
          )}
        </section>
      ) : null
    }

    render () {
      return (
        <div>
          {this.state.messageFormOpen ? (
            <MessageStudents
              contextCode={`course_${this.state.course.id}`}
              onRequestClose={this.handleMessageFormClose}
              open={this.state.messageFormOpen}
              recipients={[{
                id: this.state.user.id,
                displayName: this.state.user.short_name
              }]}
              title='Send a message'
            />
          ) : null}

          <Tray
            label={I18n.t('Student Details')}
            isDismissable={!this.state.isLoading}
            closeButtonLabel={I18n.t('Close')}
            closeButtonRef={this.getCloseButtonRef}
            isOpen={this.state.isOpen}
            onRequestClose={this.handleRequestClose}
            placement='end'
            zIndex='1000'
            onClose={this.props.onClose}
          >
            <aside
              className={(Object.keys(this.state.user).includes('avatar_url'))
                ? 'StudentContextTray StudentContextTray--withAvatar'
                : 'StudentContextTray'
              }
            >
              {this.state.isLoading ? (
                <div className='StudentContextTray__Spinner'>
                  <Spinner title={I18n.t('Loading')}
                    size='large'
                  />
                </div>
              ) : (
                <div>
                  <header className="StudentContextTray-Header">
                    <Avatar user={this.state.user}
                      canMasquerade={!!this.state.permissions.become_user}
                      courseId={this.props.courseId}
                    />

                    <div className="StudentContextTray-Header__Layout">
                      <div className="StudentContextTray-Header__Content">
                        {this.state.user.short_name  ? (
                          <div className="StudentContextTray-Header__Name">
                            <Heading level="h3" as="h2">
                              <span className="StudentContextTray-Header__NameLink">
                                <Link
                                  href={`/courses/${this.props.courseId}/users/${this.props.studentId}`}
                                  aria-label={I18n.t('Go to %{name}\'s profile', {name: this.state.user.short_name})}
                                >
                                  {this.state.user.short_name}
                                </Link>
                              </span>
                            </Heading>
                          </div>
                        ) : null}
                        <div className="StudentContextTray-Header__CourseName">
                          <Typography size="medium" as="div" lineHeight="condensed">
                            {this.state.course.name}
                          </Typography>
                        </div>
                        <Typography size="x-small" color="secondary" as="div">
                          <SectionInfo course={this.state.course} user={this.state.user} />
                        </Typography>
                        <Typography size="x-small" color="secondary" as="div">
                          <LastActivity user={this.state.user} />
                        </Typography>
                      </div>
                      {this.state.permissions.send_messages ? (
                        <div className="StudentContextTray-Header__Actions">
                          <Button
                            ref={ (b) => this.messageStudentsButton = b }
                            variant="icon" size="small"
                            onClick={this.handleMessageButtonClick}
                          >
                            <ScreenReaderContent>
                              {I18n.t('Send a message to %{student}', {student: this.state.user.short_name})}
                            </ScreenReaderContent>

                            {/* Note: replace with instructure-icon */}
                            <i className="icon-email" aria-hidden="true" />

                          </Button>
                        </div>
                      ) : null }
                    </div>
                  </header>
                  {this.renderQuickLinks()}
                  <MetricsList user={this.state.user} analytics={this.state.analytics} />
                  <SubmissionProgressBars submissions={this.state.submissions} />

                  {Object.keys(this.state.analytics).length > 0 ? (
                    <section
                      className="StudentContextTray__Section StudentContextTray-Ratings">
                      <Heading level="h4" as="h3" border="bottom">
                        {I18n.t("Activity Compared to Class")}
                      </Heading>
                      <div className="StudentContextTray-Ratings__Layout">
                        <Rating analytics={this.state.analytics}
                          label={I18n.t('Participation')}
                          metricName='participations_level' />
                        <Rating analytics={this.state.analytics}
                          label={I18n.t('Page Views')}
                          metricName='page_views_level' />
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
