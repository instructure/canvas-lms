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
import {number, string, shape, arrayOf, bool} from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconBlueprintLine,
  IconCollectionSolid,
  IconPlusLine,
  IconSettingsLine,
  IconStatsLine,
  IconPublishLine,
} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import axios from '@canvas/axios'
import {uniqBy} from 'lodash'
import $ from '@canvas/rails-flash-notifications'
import {useScope as useI18nScope} from '@canvas/i18n'
import UserLink from './UserLink'
import AddPeopleApp from '@canvas/add-people'

const I18n = useI18nScope('account_course_user_search')

export default class CoursesListRow extends React.Component {
  static propTypes = {
    id: string.isRequired,
    name: string.isRequired,
    workflow_state: string.isRequired,
    total_students: number.isRequired,
    teachers: arrayOf(
      shape({
        size: UserLink.propTypes.size,
        href: UserLink.propTypes.href,
        display_name: UserLink.propTypes.name,
        avatar_url: UserLink.propTypes.avatar_url,
      })
    ),
    teacher_count: number,
    sis_course_id: string,
    subaccount_name: string.isRequired,
    subaccount_id: string.isRequired,
    term: shape({name: string.isRequired}).isRequired,
    roles: arrayOf(shape({id: string.isRequired})),
    showSISIds: bool,
    can_create_enrollments: bool,
    blueprint: bool,
    template: bool,
    concluded: bool,
  }

  static defaultProps = {
    roles: [],
    can_create_enrollments:
      window.ENV && window.ENV.PERMISSIONS && window.ENV.PERMISSIONS.can_create_enrollments,
  }

  static displayName = 'Row'

  constructor(props) {
    super(props)

    this.state = {
      newlyEnrolledStudents: 0,
      teachersToShow: this.uniqueTeachers().slice(0, 2),
    }
  }

  getSections = () =>
    this.promiseToGetSections ||
    (this.promiseToGetSections = axios.get(
      `/api/v1/courses/${this.props.id}/sections?per_page=100`
    )).then(resp => resp.data)

  uniqueTeachers = () => uniqBy(this.props.teachers, 'id')

  handleNewEnrollments = newEnrollments => {
    if (newEnrollments && newEnrollments.length) {
      $.flashMessage({
        html: I18n.t(
          {
            one: '%{user_name} successfully enrolled into *%{course_name}*.',
            other: '%{count} people successfully enrolled into *%{course_name}*.',
          },
          {
            count: newEnrollments.length,
            user_name: newEnrollments[0].enrollment.name,
            course_name: this.props.name,
            wrappers: [`<a href="/courses/${this.props.id}">$1</a>`],
          }
        ),
      })
      const newStudents = newEnrollments.filter(e => e.enrollment.type === 'StudentEnrollment')
      this.setState(oldState => {
        const newlyEnrolledStudents = oldState.newlyEnrolledStudents + newStudents.length
        return {newlyEnrolledStudents}
      })
    }
  }

  getAvailableRoles = () => {
    const filterFunc = ENV.FEATURES.granular_permissions_manage_users
      ? role => role.addable_by_user
      : role => role.manageable_by_user

    let roles = (this.props.roles || []).filter(filterFunc)
    if (this.props.blueprint) {
      roles = roles.filter(
        role =>
          role.base_role_name != 'StudentEnrollment' && role.base_role_name != 'ObserverEnrollment'
      )
    }
    return roles
  }

  openAddUsersToCourseDialog = () => {
    // eslint-disable-next-line promise/catch-or-return
    this.getSections().then(sections => {
      this.addPeopleApp =
        this.addPeopleApp ||
        new AddPeopleApp(document.createElement('div'), {
          courseId: this.props.id,
          courseName: this.props.name,
          defaultInstitutionName: ENV.ROOT_ACCOUNT_NAME || '',
          roles: this.getAvailableRoles(),
          sections,
          onClose: () => {
            this.handleNewEnrollments(this.addPeopleApp.usersHaveBeenEnrolled())
          },
          inviteUsersURL: `/courses/${this.props.id}/invite_users`,
          canReadSIS: this.props.showSISIds,
        })
      this.addPeopleApp.open()
    })
  }

  showMoreTeachers = () => {
    this.setState({teachersToShow: this.uniqueTeachers()})
  }

  allowAddingEnrollments() {
    return this.props.can_create_enrollments && !this.props.concluded && !this.props.template
  }

  renderAddEnrollments() {
    if (this.allowAddingEnrollments()) {
      const {name} = this.props
      const addUsersTip = I18n.t('Add Users to %{name}', {name})
      return (
        <Tooltip renderTip={addUsersTip}>
          <IconButton
            withBorder={false}
            withBackground={false}
            size="small"
            onClick={this.openAddUsersToCourseDialog}
            screenReaderLabel={addUsersTip}
          >
            <IconPlusLine title={addUsersTip} />
          </IconButton>
        </Tooltip>
      )
    }
  }

  render() {
    const {
      id,
      name,
      workflow_state,
      sis_course_id,
      total_students,
      teachers,
      teacher_count,
      subaccount_name,
      subaccount_id,
      showSISIds,
      term,
      blueprint,
      template,
    } = this.props
    const {teachersToShow, newlyEnrolledStudents} = this.state
    const url = `/courses/${id}`
    const sub_url = `/accounts/${subaccount_id}`
    const isPublished = workflow_state !== 'unpublished'

    const blueprintTip = I18n.t('This is a blueprint course')
    const statsTip = I18n.t('Statistics for %{name}', {name})
    const settingsTip = I18n.t('Settings for %{name}', {name})
    const templateTip = I18n.t('This is a course template')

    return (
      <Table.Row>
        <Table.RowHeader textAlign="center">
          {isPublished ? (
            <span className="published-status published">
              <IconPublishLine size="x-small" />
              <ScreenReaderContent>{I18n.t('yes')}</ScreenReaderContent>
            </span>
          ) : (
            <span className="published-status unpublished">
              <ScreenReaderContent>{I18n.t('no')}</ScreenReaderContent>
            </span>
          )}
        </Table.RowHeader>
        <Table.Cell>
          <a href={url}>
            <span style={{paddingRight: '0.5em'}}>{name}</span>
            {blueprint && (
              <Tooltip renderTip={blueprintTip}>
                <IconBlueprintLine />
                <ScreenReaderContent>{blueprintTip}</ScreenReaderContent>
              </Tooltip>
            )}
            {template && (
              <Tooltip renderTip={templateTip}>
                <IconCollectionSolid />
                <ScreenReaderContent>{templateTip}</ScreenReaderContent>
              </Tooltip>
            )}
          </a>
        </Table.Cell>
        {showSISIds && <Table.Cell>{sis_course_id}</Table.Cell>}
        <Table.Cell>{template ? '\u2014' : term.name}</Table.Cell>
        <Table.Cell>
          {(teachersToShow || []).map(teacher => (
            <div key={teacher.id}>
              <UserLink
                key={teacher.id}
                href={teacher.html_url}
                name={teacher.display_name}
                avatarName={teacher.display_name}
                avatar_url={teacher.avatar_image_url}
                size="x-small"
              />
            </div>
          ))}
          {teachers && teachers.length > 2 && teachersToShow.length === 2 && (
            <Link isWithinText={false} as="button" onClick={this.showMoreTeachers}>
              <Text size="small">{I18n.t('Show More')}</Text>
            </Link>
          )}
          {!teachers && teacher_count && I18n.t('%{teacher_count} teachers', {teacher_count})}
        </Table.Cell>
        <Table.Cell>
          <a href={sub_url}>{subaccount_name}</a>
        </Table.Cell>
        <Table.Cell>
          {template ? '\u2014' : I18n.n(total_students + newlyEnrolledStudents)}
        </Table.Cell>
        <Table.Cell textAlign="end">
          {this.renderAddEnrollments()}
          <Tooltip renderTip={statsTip}>
            <IconButton
              withBorder={false}
              withBackground={false}
              size="small"
              href={`${url}/statistics`}
              screenReaderLabel={statsTip}
            >
              <IconStatsLine title={statsTip} />
            </IconButton>
          </Tooltip>
          <Tooltip renderTip={settingsTip}>
            <IconButton
              withBorder={false}
              withBackground={false}
              size="small"
              href={`${url}/settings`}
              screenReaderLabel={settingsTip}
            >
              <IconSettingsLine title={settingsTip} />
            </IconButton>
          </Tooltip>
        </Table.Cell>
      </Table.Row>
    )
  }
}
