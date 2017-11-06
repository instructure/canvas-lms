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

import $ from 'jquery'
import React from 'react'
import {number, string, shape, arrayOf} from 'prop-types'
import Button from 'instructure-ui/lib/components/Button'
import Tooltip from 'instructure-ui/lib/components/Tooltip'
import IconPlusLine from 'instructure-icons/lib/Line/IconPlusLine'
import IconSettingsLine from 'instructure-icons/lib/Line/IconSettingsLine'
import IconStatsLine from 'instructure-icons/lib/Line/IconStatsLine'
import _ from 'underscore'
import I18n from 'i18n!account_course_user_search'
import UserLink from './UserLink'
import AddPeopleApp from '../add_people/add_people_app'

const uniqueTeachers = teachers => _.uniq(teachers, teacher => teacher.id)

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
  }

  static defaultProps = {
    roles: []
  }

  constructor(props) {
    super(props)

    const teachers = uniqueTeachers(props.teachers)
    this.state = {
      newlyEnrolledStudents: 0,
      teachersToShow: _.compact([teachers[0], teachers[1]])
    }
  }

  getSections = () =>
    this.promiseToGetSections ||
    (this.promiseToGetSections = $.get(`/api/v1/courses/${this.props.id}/sections?per_page=100`))

  handleNewEnrollments = newEnrollments => {
    if (newEnrollments && newEnrollments.length) {
      $.flashMessage( I18n.t( {
        one: '%{user_name} successfully enrolled into *%{course_name}*.',
        other: '%{count} people successfully enrolled into *%{course_name}*.'
      },{
        count: newEnrollments.length,
        user_name: newEnrollments[0].enrollment.name,
        course_name: this.props.name,
        wrappers: [
          `<a href="/courses/${this.props.id}">$1</a>`
        ]
      }))
      const newStudents = newEnrollments.filter(e => e.enrollment.type === 'StudentEnrollment')
      this.setState({newlyEnrolledStudents: this.state.newlyEnrolledStudents + newStudents.length})
    }
  }

  openAddUsersToCourseDialog = () => {
    this.getSections().then(sections => {
      this.addPeopleApp = this.addPeopleApp || new AddPeopleApp($('<div />')[0], {
        courseId: this.props.id,
        courseName: this.props.name,
        defaultInstitutionName: ENV.ROOT_ACCOUNT_NAME || '',
        roles: (this.props.roles || []).filter(role => role.manageable_by_user),
        sections,
        onClose: () => {
          this.handleNewEnrollments(this.addPeopleApp.usersHaveBeenEnrolled())
        },
        inviteUsersURL: `/courses/${this.props.id}/invite_users`,
        canReadSIS: true // Since we show course SIS ids in search results, I assume anyone that gets here can read SIS
      })
      this.addPeopleApp.open()
    })
  }

  showMoreTeachers = () => {
    this.setState({teachersToShow: uniqueTeachers(this.props.teachers)})
  }

  render() {
    const {id, name, workflow_state, sis_course_id, total_students, subaccount_name} = this.props
    const url = `/courses/${id}`
    const isPublished = workflow_state !== 'unpublished'

    return (
      <div role="row" className="grid-row pad-box-mini border border-b">
        <div className="col-xs-3">
          <div role="gridcell" className="grid-row middle-xs">
            <div className="col-xs-2">
              {isPublished && (
                <Tooltip tip={I18n.t('Published')}>
                  <i className="icon-publish icon-Solid courses-list__published-icon" />
                </Tooltip>
              )}
            </div>
            <div className="col-xs-10">
              <a href={url}>{name}</a>
            </div>
          </div>
        </div>

        <div className="col-xs-1" role="gridcell">
          {sis_course_id}
        </div>

        <div className="col-xs-1" role="gridcell">
          {this.props.term.name}
        </div>

        <div className="col-xs-2" role="gridcell">
          {(this.state.teachersToShow || []).map(teacher =>
            <UserLink key={teacher.id} {...teacher} />
          )}
          {this.props.teachers.length > 2 && this.state.teachersToShow.length === 2 &&
            <Button variant="link" onClick={this.showMoreTeachers}>
              {I18n.t('Show More')}
            </Button>
          }
        </div>

        <div className="col-xs-2" role="gridcell">
          {subaccount_name}
        </div>

        <div className="col-xs-1" role="gridcell">
          {I18n.n(total_students + this.state.newlyEnrolledStudents)}
        </div>
        <div className="col-xs-2" role="gridcell">
          <div className="courses-user-list-actions">
            <Tooltip tip={I18n.t('Add Users to %{name}', {name})}>
              <Button variant="icon" size="small" onClick={this.openAddUsersToCourseDialog}>
                <IconPlusLine />
              </Button>
            </Tooltip>
            <Tooltip tip={I18n.t('Statistics for %{name}', {name})}>
              <Button variant="icon" size="small" href={`${url}/statistics`}>
                <IconStatsLine />
              </Button>
            </Tooltip>
            <Tooltip tip={I18n.t('Settings for %{name}', {name})}>
              <Button variant="icon" size="small" href={`${url}/settings`}>
                <IconSettingsLine />
              </Button>
            </Tooltip>
          </div>
        </div>
      </div>
    )
  }
}
