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
import IconMiniArrowUpSolid from 'instructure-icons/lib/Solid/IconMiniArrowUpSolid'
import IconMiniArrowDownSolid from 'instructure-icons/lib/Solid/IconMiniArrowDownSolid'
import Link from 'instructure-ui/lib/components/Link'
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

  renderHeader ({id, label, tipDesc, tipAsc}) {
    return (

      <Tooltip
        as={Link}
        tip={(this.props.sort === id && this.props.order === 'asc') ? tipAsc : tipDesc}
        onClick={preventDefault(() => this.props.onChangeSort(id))}
      >
        {label}
        {this.props.sort === id ?
          (this.props.order === 'asc' ? <IconMiniArrowDownSolid /> : <IconMiniArrowUpSolid />) :
          ''
        }
      </Tooltip>
    )
  }

  render () {
    const courses = this.props.courses

    return (
      <div className="content-box" role="grid">
        <div role="row" className="grid-row border border-b pad-box-mini">
          <div className="col-xs-3">
            <div className="grid-row">
              <div className="col-xs-2" />
              <div className="col-xs-10" role="columnheader">
              {this.renderHeader({
                id: 'course_name',
                label: I18n.t('Course'),
                tipDesc: I18n.t('Click to sort by name ascending'),
                tipAsc: I18n.t('Click to sort by name descending')
              })}
              </div>
            </div>
          </div>
          <div role="columnheader" className="col-xs-1">
            {this.renderHeader({
              id: 'sis_course_id',
              label: I18n.t('SIS ID'),
              tipDesc: I18n.t('Click to sort by SIS ID ascending'),
              tipAsc: I18n.t('Click to sort by SIS ID descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-1">
            {this.renderHeader({
              id: 'term',
              label: I18n.t('Term'),
              tipDesc: I18n.t('Click to sort by term ascending'),
              tipAsc: I18n.t('Click to sort by term descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-2">
            {this.renderHeader({
              id: 'teacher',
              label: I18n.t('Teacher'),
              tipDesc: I18n.t('Click to sort by teacher ascending'),
              tipAsc: I18n.t('Click to sort by teacher descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-2">
            {this.renderHeader({
              id: 'subaccount',
              label: I18n.t('Sub-Account'),
              tipDesc: I18n.t('Click to sort by sub-account ascending'),
              tipAsc: I18n.t('Click to sort by sub-account descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-2">
            {this.renderHeader({
              id: 'enrollments',
              label: I18n.t('Enrollments'),
              tipDesc: I18n.t('Click to sort by enrollments ascending'),
              tipAsc: I18n.t('Click to sort by enrollments descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-1">
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
