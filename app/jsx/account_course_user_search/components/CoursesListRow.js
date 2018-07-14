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
import Button from '@instructure/ui-buttons/lib/components/Button'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import IconBlueprintLine from '@instructure/ui-icons/lib/Line/IconBlueprint'
import IconPlusLine from '@instructure/ui-icons/lib/Line/IconPlus'
import IconSettingsLine from '@instructure/ui-icons/lib/Line/IconSettings'
import IconStatsLine from '@instructure/ui-icons/lib/Line/IconStats'
import {get} from 'axios'
import {uniqBy} from 'lodash'
import {flashMessage} from 'compiled/jquery.rails_flash_notifications'
import I18n from 'i18n!account_course_user_search'
import UserLink from './UserLink'
import AddPeopleApp from '../../add_people/add_people_app'

export default class CoursesListRow extends React.Component {
  static propTypes = {
    id: string.isRequired,
    name: string.isRequired,
    workflow_state: string.isRequired,
    total_students: number.isRequired,
    teachers: arrayOf(shape(UserLink.propTypes)).isRequired,
    sis_course_id: string,
    subaccount_name: string.isRequired,
    term: shape({name: string.isRequired}).isRequired,
    roles: arrayOf(shape({id: string.isRequired})),
    showSISIds: bool.isRequired,
    can_create_enrollments: bool,
    blueprint: bool
  }

  static defaultProps = {
    roles: [],
    can_create_enrollments:
      window.ENV &&
      window.ENV.PERMISSIONS &&
      window.ENV.PERMISSIONS.can_create_enrollments
  }

  constructor(props) {
    super(props)

    this.state = {
      newlyEnrolledStudents: 0,
      teachersToShow: this.uniqueTeachers().slice(0, 2)
    }
  }

  getSections = () =>
    this.promiseToGetSections ||
    (this.promiseToGetSections = get(`/api/v1/courses/${this.props.id}/sections?per_page=100`)).then(resp => resp.data)

  uniqueTeachers = () => uniqBy(this.props.teachers, 'id')

  handleNewEnrollments = newEnrollments => {
    if (newEnrollments && newEnrollments.length) {
      flashMessage({
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
      this.setState({newlyEnrolledStudents: this.state.newlyEnrolledStudents + newStudents.length})
    }
  }

  openAddUsersToCourseDialog = () => {
    this.getSections().then(sections => {
      this.addPeopleApp =
        this.addPeopleApp ||
        new AddPeopleApp(document.createElement('div'), {
          courseId: this.props.id,
          courseName: this.props.name,
          defaultInstitutionName: ENV.ROOT_ACCOUNT_NAME || '',
          roles: (this.props.roles || []).filter(role => role.manageable_by_user),
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

  render() {
    const {
      id,
      name,
      workflow_state,
      sis_course_id,
      total_students,
      teachers,
      subaccount_name,
      showSISIds,
      term,
      blueprint,
      can_create_enrollments
    } = this.props
    const {teachersToShow, newlyEnrolledStudents} = this.state
    const url = `/courses/${id}`
    const isPublished = workflow_state !== 'unpublished'

    const blueprintTip = I18n.t('This is a blueprint course')
    const addUsersTip = I18n.t('Add Users to %{name}', {name})
    const statsTip = I18n.t('Statistics for %{name}', {name})
    const settingsTip = I18n.t('Settings for %{name}', {name})

    return (
      <tr>
        <th scope="row">
        {isPublished && (
          <Tooltip tip={I18n.t('Published')}>
            <span className="published-status published">
              <i className="icon-publish" />
            </span>
          </Tooltip>
        )}
        </th>
        <td>
          <a href={url}>
            {name}
            {blueprint && (
              <Tooltip tip={blueprintTip}>
                {' '}
                <IconBlueprintLine />
                <ScreenReaderContent>{blueprintTip}</ScreenReaderContent>
              </Tooltip>
            )}
          </a>
        </td>
        {showSISIds && <td>{sis_course_id}</td>}
        <td>{term.name}</td>
        <td>
          {(teachersToShow || []).map(teacher => (
            <div>
            <UserLink
              key={teacher.id}
              href={teacher.html_url}
              name={teacher.display_name}
              avatar_url={teacher.avatar_image_url}
              size="x-small"
            />
            </div>
          ))}
          {teachers.length > 2 &&
            teachersToShow.length === 2 && (
              <Button variant="link" size="small" onClick={this.showMoreTeachers}>
                {I18n.t('Show More')}
              </Button>
            )}
        </td>
        <td>{subaccount_name}</td>
        <td>{I18n.n(total_students + newlyEnrolledStudents)}</td>
        <td style={{whiteSpace: 'nowrap'}}>
          {can_create_enrollments && (
            <Tooltip tip={addUsersTip}>
              <Button variant="icon" size="small" onClick={this.openAddUsersToCourseDialog}>
                <IconPlusLine title={addUsersTip} />
              </Button>
            </Tooltip>
          )}
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
        </td>
      </tr>
    )
  }
}
