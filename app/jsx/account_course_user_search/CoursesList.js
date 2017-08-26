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

import preventDefault from 'compiled/fn/preventDefault'
import IconArrowUpSolid from 'instructure-icons/lib/Solid/IconArrowUpSolid'
import IconArrowDownSolid from 'instructure-icons/lib/Solid/IconArrowDownSolid'
import Typography from 'instructure-ui/lib/components/Typography'
import Tooltip from 'instructure-ui/lib/components/Tooltip'
import React from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'
import I18n from 'i18n!account_course_user_search'
import axios from 'axios'
import CoursesListRow from './CoursesListRow'

const { string, shape, arrayOf, func } = PropTypes

class CoursesList extends React.Component {
  static propTypes = {
    courses: arrayOf(shape(CoursesListRow.propTypes)).isRequired,
    addUserUrls: shape({
      USER_LISTS_URL: string.isRequired,
      ENROLL_USERS_URL: string.isRequired,
    }).isRequired,
    onChangeSort: func.isRequired,
    roles: arrayOf(shape({ id: string.isRequired })),
    sort: string,
    order: string,
  };

  static defaultProps = {
    sort: 'sis_course_id',
    order: 'asc',
    roles: [],
  };

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
    const sort = this.props.sort
    const order = this.props.order

    const courseLabel = I18n.t('Course')
    const idLabel = I18n.t('SIS ID')
    const teacherLabel = I18n.t('Teacher')
    const enrollmentsLabel = I18n.t('Enrollments')
    const subaccountLabel = I18n.t('Sub-Account')

    let courseTip
    let idTip
    let teacherTip
    let enrollmentsTip
    let subaccountTip

    let courseArrow = ''
    let idArrow = ''
    let teacherArrow = ''
    let enrollmentsArrow = ''
    let subaccountArrow = ''

    if (sort === 'course_name') {
      idTip = I18n.t('Click to sort by SIS ID ascending')
      teacherTip = I18n.t('Click to sort by teacher ascending')
      enrollmentsTip = I18n.t('Click to sort by enrollments ascending')
      subaccountTip = I18n.t('Click to sort by subaccount ascending')
      if (order === 'asc') {
        courseTip = I18n.t('Click to sort by name descending')
        courseArrow = <IconArrowDownSolid />
      } else {
        courseTip = I18n.t('Click to sort by name ascending')
        courseArrow = <IconArrowUpSolid />
      }
    } else if (sort === 'sis_course_id') {
      courseTip = I18n.t('Click to sort by name ascending')
      teacherTip = I18n.t('Click to sort by teacher ascending')
      enrollmentsTip = I18n.t('Click to sort by enrollments ascending')
      subaccountTip = I18n.t('Click to sort by subaccount ascending')
      if (order === 'asc') {
        idTip = I18n.t('Click to sort by SIS ID descending')
        idArrow = <IconArrowDownSolid />
      } else {
        idTip = I18n.t('Click to sort by SIS ID ascending')
        idArrow = <IconArrowUpSolid />
      }
    } else if (sort === 'teacher') {
      courseTip = I18n.t('Click to sort by name ascending')
      idTip = I18n.t('Click to sort by SIS ID ascending')
      enrollmentsTip = I18n.t('Click to sort by enrollments ascending')
      subaccountTip = I18n.t('Click to sort by subaccount ascending')
      if (order === 'asc') {
        teacherTip = I18n.t('Click to sort by teacher descending')
        teacherArrow = <IconArrowDownSolid />
      } else {
        teacherTip = I18n.t('Click to sort by teacher ascending')
        teacherArrow = <IconArrowUpSolid />
      }
    } else if (sort === 'enrollments') {
      courseTip = I18n.t('Click to sort by name ascending')
      idTip = I18n.t('Click to sort by SIS ID ascending')
      teacherTip = I18n.t('Click to sort by teacher ascending')
      subaccountTip = I18n.t('Click to sort by subaccount ascending')
      if (order === 'asc') {
        enrollmentsTip = I18n.t('Click to sort by enrollments descending')
        enrollmentsArrow = <IconArrowDownSolid />
      } else {
        enrollmentsTip = I18n.t('Click to sort by enrollments ascending')
        enrollmentsArrow = <IconArrowUpSolid />
      }
    } else if (sort === 'subaccount') {
      courseTip = I18n.t('Click to sort by name ascending')
      idTip = I18n.t('Click to sort by SIS ID ascending')
      teacherTip = I18n.t('Click to sort by teacher ascending')
      enrollmentsTip = I18n.t('Click to sort by enrollments ascending')
      if (order === 'asc') {
        subaccountTip = I18n.t('Click to sort by subaccount descending')
        subaccountArrow = <IconArrowDownSolid />
      } else {
        subaccountTip = I18n.t('Click to sort by subaccount ascending')
        subaccountArrow = <IconArrowUpSolid />
      }
    }


    const courses = this.props.courses

    return (
      <div className="content-box" role="grid">
        <div role="row" className="grid-row border border-b pad-box-mini">
          <div className="col-xs-3">
            <div className="grid-row">
              <div className="col-xs-2" />
              <div className="col-xs-10" role="columnheader">
                <a
                  role="button"
                  href=""
                  className="courses-user-list-header"
                  onClick={preventDefault(() => this.props.onChangeSort('course_name'))}
                >
                  <Tooltip as={Typography} tip={courseTip}>
                    {courseLabel}
                    {courseArrow}
                  </Tooltip>
                </a>
              </div>
            </div>
          </div>
          <div role="columnheader" className="col-xs-1">
            <a
              role="button"
              href=""
              className="courses-user-list-header"
              onClick={preventDefault(() => this.props.onChangeSort('sis_course_id'))}
            >
              <Tooltip as={Typography} tip={idTip}>
                {idLabel}
                {idArrow}
              </Tooltip>
            </a>
          </div>
          <div role="columnheader" className="col-xs-2">
            <a
              role="button"
              href=""
              className="courses-user-list-header"
              onClick={preventDefault(() => this.props.onChangeSort('teacher'))}
            >
              <Tooltip as={Typography} tip={teacherTip}>
                {teacherLabel}
                {teacherArrow}
              </Tooltip>
            </a>
          </div>
          <div role="columnheader" className="col-xs-2">
            <a
              role="button"
              href=""
              className="courses-user-list-header"
              onClick={preventDefault(() => this.props.onChangeSort('subaccount'))}
            >
              <Tooltip as={Typography} tip={subaccountTip}>
                {subaccountLabel}
                {subaccountArrow}
              </Tooltip>
            </a>
          </div>
          <div role="columnheader" className="col-xs-1">
            <a
              role="button"
              href=""
              className="courses-user-list-header"
              onClick={preventDefault(() => this.props.onChangeSort('enrollments'))}
            >
              <Tooltip as={Typography} tip={enrollmentsTip}>
                {enrollmentsLabel}
                {enrollmentsArrow}
              </Tooltip>
            </a>
          </div>
          <div role="columnheader" className="col-xs-2">
            <span className="screenreader-only">{I18n.t('Course option links')}</span>
          </div>
        </div>

        <div className="courses-list" role="rowgroup">
          {courses.map((course) => {
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
