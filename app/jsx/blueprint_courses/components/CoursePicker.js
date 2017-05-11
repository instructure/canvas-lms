/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!blueprint_settings'
import $ from 'jquery'
import React from 'react'
import ToggleDetails from 'instructure-ui/lib/components/ToggleDetails'
import Typography from 'instructure-ui/lib/components/Typography'
import Spinner from 'instructure-ui/lib/components/Spinner'
import 'compiled/jquery.rails_flash_notifications'
import propTypes from '../propTypes'
import CourseFilter from './CourseFilter'
import CoursePickerTable from './CoursePickerTable'

const { func, bool, arrayOf, string } = React.PropTypes

export default class CoursePicker extends React.Component {
  static propTypes = {
    courses: propTypes.courseList.isRequired,
    terms: propTypes.termList.isRequired,
    subAccounts: propTypes.accountList.isRequired,
    selectedCourses: arrayOf(string).isRequired,
    loadCourses: func.isRequired,
    isLoadingCourses: bool.isRequired,
    onSelectedChanged: func,
    isExpanded: bool,
  }

  static defaultProps = {
    onSelectedChanged: () => {},
    isExpanded: true,
  }

  constructor (props) {
    super(props)
    this.state = {
      isExpanded: props.isExpanded,
      isManuallyExpanded: props.isExpanded,
      announceChanges: false,
    }
  }

  componentWillReceiveProps (nextProps) {
    if (this.state.announceChanges && !this.props.isLoadingCourses && nextProps.isLoadingCourses) {
      $.screenReaderFlashMessage(I18n.t('Loading courses started'))
    }

    if (this.state.announceChanges && this.props.isLoadingCourses && !nextProps.isLoadingCourses) {
      this.setState({ announceChanges: false })
      $.screenReaderFlashMessage(I18n.t({
        one: 'Loading courses complete: one course found',
        other: 'Loading courses complete: %{count} courses found'
      }, { count: nextProps.courses.length }))
    }
  }

  onFilterActivate = () => {
    this.setState({
      isExpanded: true,
      isManuallyExpanded: this.coursesToggle.state.isExpanded,
    })
  }

  onFilterDeactivate = () => {
    if (this.state.isExpanded && !this.state.isManuallyExpanded) {
      this.setState({ isExpanded: false })
    }
  }

  onSelectedChanged = (selected) => {
    this.props.onSelectedChanged(selected)
    this.setState({ isExpanded: true })
  }

  // when the filter updates, load new courses
  onFilterChange = (filters) => {
    this.props.loadCourses(filters)

    this.setState({
      filters,
      isExpanded: true,
      announceChanges: true,
    })
  }

  reloadCourses () {
    this.props.loadCourses(this.state.filters)
  }

  render () {
    return (
      <div className="bca-course-picker">
        <CourseFilter
          ref={(c) => { this.filter = c }}
          terms={this.props.terms}
          subAccounts={this.props.subAccounts}
          onChange={this.onFilterChange}
          onActivate={this.onFilterActivate}
          onDeactivate={this.onFilterDeactivate}
        />
        <div className="bca-course-details__wrapper">
          <ToggleDetails
            ref={(c) => { this.coursesToggle = c }}
            isExpanded={this.state.isExpanded}
            summary={<Typography>{I18n.t('Courses')}</Typography>}
          >
            {this.props.isLoadingCourses && (<div className="bca-course-picker__loading">
              <Spinner title={I18n.t('Loading Courses')} />
            </div>)}
            <CoursePickerTable
              courses={this.props.courses}
              selectedCourses={this.props.selectedCourses}
              onSelectedChanged={this.onSelectedChanged}
            />
          </ToggleDetails>
        </div>
      </div>
    )
  }
}
