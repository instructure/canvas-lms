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
import PropTypes from 'prop-types'
import $ from 'jquery'
import I18n from 'i18n!account_course_user_search'
import natcompare from 'compiled/util/natcompare'
import axios from 'axios'
import CoursesListRow from './CoursesListRow'

const { string, shape, arrayOf } = PropTypes

  class CoursesList extends React.Component {
    static propTypes = {
      courses: arrayOf(shape(CoursesListRow.propTypes)).isRequired,
      addUserUrls: shape({
        USER_LISTS_URL: string.isRequired,
        ENROLL_USERS_URL: string.isRequired,
      }).isRequired,
      roles: arrayOf(shape({ id: string.isRequired })).isRequired,
    }

    constructor () {
      super()
      this.state = {
        sections: [],
      }
    }

    componentWillMount () {
      this.props.courses.forEach((course) => {
        axios
          .get(`/api/v1/courses/${course.id}/sections`)
          .then((response) => {
            this.setState({
              sections: this.state.sections.concat(response.data)
            })
          })
      })
    }

    render () {
      const courses = this.props.courses

      return (
        <div className="content-box" role="grid">
          <div role="row" className="grid-row border border-b pad-box-mini">
            <div className="col-xs-5">
              <div className="grid-row">
                <div className="col-xs-2" />
                <div className="col-xs-10" role="columnheader">
                  <span className="courses-user-list-header">
                    {I18n.t('Course')}
                  </span>
                </div>
              </div>
            </div>
            <div role="columnheader" className="col-xs-1">
              <span className="courses-user-list-header">
                {I18n.t('SIS ID')}
              </span>
            </div>
            <div role="columnheader" className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t('Teacher')}
              </span>
            </div>
            <div role="columnheader" className="col-xs-1">
              <span className="courses-user-list-header">
                {I18n.t('Enrollments')}
              </span>
            </div>
            <div role="columnheader" className="col-xs-2">
              <span className="screenreader-only">{I18n.t('Course option links')}</span>
            </div>
          </div>

          <div className="courses-list" role="rowgroup">
            {courses.sort(natcompare.byKey('name')).map((course) => {
              const urlsForCourse = {
                USER_LISTS_URL: $.replaceTags(this.props.addUserUrls.USER_LISTS_URL, 'id', course.id),
                ENROLL_USERS_URL: $.replaceTags(this.props.addUserUrls.ENROLL_USERS_URL, 'id', course.id)
              }

              const courseSections = this.state.sections.filter(section => section.course_id === parseInt(course.id, 10))

              return (
                <CoursesListRow
                  key={course.id}
                  courseModel={courses}
                  roles={this.props.roles}
                  urls={urlsForCourse}
                  sections={courseSections}
                  {...course}
                />
              )
            })}
          </div>
        </div>
      )
    }
  }

export default CoursesList
