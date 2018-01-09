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

import I18n from 'i18n!new_nav'
import React from 'react'
import PropTypes from 'prop-types'
import SVGWrapper from '../../shared/SVGWrapper'
import Spinner from 'instructure-ui/lib/components/Spinner'

  var CoursesTray = React.createClass({
    propTypes: {
      courses: PropTypes.array.isRequired,
      closeTray: PropTypes.func.isRequired,
      hasLoaded: PropTypes.bool.isRequired
    },

    getDefaultProps() {
      return {
        courses: []
      };
    },

    renderCourses() {
      if (!this.props.hasLoaded) {
        return (
          <li className="ic-NavMenu-list-item ic-NavMenu-list-item--loading-message">
            <Spinner size="small" title={I18n.t('Loading')} />
          </li>
        );
      }
      var courses = this.props.courses.map((course) => {
        return (
          <li key={course.id} className='ic-NavMenu-list-item'>
            <a href={`/courses/${course.id}`} className='ic-NavMenu-list-item__link'>{course.name}</a>
            { course.enrollment_term_id > 1 ? ( <div className='ic-NavMenu-list-item__helper-text'>{course.term.name}</div> ) : null }
          </li>
        );
      });
      courses.push(
        <li key='allCourseLink' className='ic-NavMenu-list-item ic-NavMenu-list-item--feature-item'>
          <a href='/courses' className='ic-NavMenu-list-item__link'>{I18n.t('All Courses')}</a>
        </li>
      );
      return courses;
    },

    render() {
      return (
        <div className="ic-NavMenu__layout">
          <div className="ic-NavMenu__primary-content">
            <div className="ic-NavMenu__header">
              <h1 className="ic-NavMenu__headline">{I18n.t('Courses')}</h1>
              <button className="Button Button--icon-action ic-NavMenu__closeButton" type="button" onClick={this.props.closeTray}>
                <i className="icon-x"></i>
                <span className="screenreader-only">{I18n.t('Close')}</span>
              </button>
            </div>
            <ul className="ic-NavMenu__link-list">
              {this.renderCourses()}
            </ul>
          </div>
          <div className="ic-NavMenu__secondary-content">
              {I18n.t('Welcome to your courses! To customize the list of courses, ' +
                      'click on the "All Courses" link and star the courses to display.')}
          </div>
        </div>
      );
    }
  });

export default CoursesTray
