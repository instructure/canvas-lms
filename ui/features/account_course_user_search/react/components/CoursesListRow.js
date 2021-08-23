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
import {Button} from '@instructure/ui-buttons'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconBlueprintLine,
  IconCollectionSolid,
  IconPlusLine,
  IconSettingsLine,
  IconStatsLine,
  IconPublishLine
} from '@instructure/ui-icons'
import axios from '@canvas/axios'
import {uniqBy} from 'lodash'
import $ from '@canvas/rails-flash-notifications'
import I18n from 'i18n!account_course_user_search'
import UserLink from './UserLink'
import AddPeopleApp from '@canvas/add-people'

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
        avatar_url: UserLink.propTypes.src
      })
    ),
    teacher_count: number,
    sis_course_id: string,
    subaccount_name: string.isRequired,
    term: shape({name: string.isRequired}).isRequired,
    roles: arrayOf(shape({id: string.isRequired})),
    showSISIds: bool,
    can_create_enrollments: bool,
    blueprint: bool,
    template: bool,
    concluded: bool
  }

  static defaultProps = {
    roles: [],
    can_create_enrollments:
      window.ENV && window.ENV.PERMISSIONS && window.ENV.PERMISSIONS.can_create_enrollments
  }

  static displayName = 'Row'

  constructor(props) {
    super(props)

    this.state = {
      newlyEnrolledStudents: 0,
      teachersToShow: this.uniqueTeachers().slice(0, 2)
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
            other: '%{count} people successfully enrolled into *%{course_name}*.'
          },
          {
            count: newEnrollments.length,
            user_name: newEnrollments[0].enrollment.name,
            course_name: this.props.name,
            wrappers: [`<a href="/courses/${this.props.id}">$1</a>`]
          }
        )
      })
      const newStudents = newEnrollments.filter(e => e.enrollment.type === 'StudentEnrollment')
      this.setState(oldState => {
        const newlyEnrolledStudents = oldState.newlyEnrolledStudents + newStudents.length
        return {newlyEnrolledStudents}
      })
    }
  }

  openAddUsersToCourseDialog = () => {
    const filterFunc = ENV.FEATURES.granular_permissions_manage_users
      ? role => role.addable_by_user
      : role => role.manageable_by_user
    // eslint-disable-next-line promise/catch-or-return
    this.getSections().then(sections => {
      this.addPeopleApp =
        this.addPeopleApp ||
        new AddPeopleApp(document.createElement('div'), {
          courseId: this.props.id,
          courseName: this.props.name,
          defaultInstitutionName: ENV.ROOT_ACCOUNT_NAME || '',
          roles: (this.props.roles || []).filter(filterFunc),
          sections,
          onClose: () => {
            this.handleNewEnrollments(this.addPeopleApp.usersHaveBeenEnrolled())
          },
          inviteUsersURL: `/courses/${this.props.id}/invite_users`,
          canReadSIS: this.props.showSISIds
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
        <Tooltip tip={addUsersTip}>
          <Button variant="icon" size="small" onClick={this.openAddUsersToCourseDialog}>
            <IconPlusLine title={addUsersTip} />
          </Button>
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
      showSISIds,
      term,
      blueprint,
      template
    } = this.props
    const {teachersToShow, newlyEnrolledStudents} = this.state
    const url = `/courses/${id}`
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
              <Tooltip tip={blueprintTip}>
                <IconBlueprintLine />
                <ScreenReaderContent>{blueprintTip}</ScreenReaderContent>
              </Tooltip>
            )}
            {template && (
              <Tooltip tip={templateTip}>
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
                avatar_url={teacher.avatar_image_url}
                size="x-small"
              />
            </div>
          ))}
          {teachers && teachers.length > 2 && teachersToShow.length === 2 && (
            <Button variant="link" size="small" onClick={this.showMoreTeachers}>
              {I18n.t('Show More')}
            </Button>
          )}
          {!teachers && teacher_count && I18n.t('%{teacher_count} teachers', {teacher_count})}
        </Table.Cell>
        <Table.Cell>{subaccount_name}</Table.Cell>
        <Table.Cell>
          {template ? '\u2014' : I18n.n(total_students + newlyEnrolledStudents)}
        </Table.Cell>
        <Table.Cell textAlign="end">
          {this.renderAddEnrollments()}
          <Tooltip tip={statsTip}>
            <Button variant="icon" size="small" href={`${url}/statistics`}>
              <IconStatsLine title={statsTip} />
            </Button>
          </Tooltip>
          <Tooltip tip={settingsTip}>
            <Button variant="icon" size="small" href={`${url}/settings`}>
              <IconSettingsLine title={settingsTip} />
            </Button>
          </Tooltip>
        </Table.Cell>
      </Table.Row>
    )
  }
}
