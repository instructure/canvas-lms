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
import PropTypes from 'prop-types'
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleDetails'
import Text from '@instructure/ui-elements/lib/components/Text'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import 'compiled/jquery.rails_flash_notifications'
import propTypes from '../propTypes'
import CourseFilter from './CourseFilter'
import CoursePickerTable from './CoursePickerTable'

const { func, bool, arrayOf, string } = PropTypes

export default class CoursePicker extends React.Component {
  static propTypes = {
    courses: propTypes.courseList.isRequired,
    terms: propTypes.termList.isRequired,
    subAccounts: propTypes.accountList.isRequired,
    selectedCourses: arrayOf(string).isRequired,
    loadCourses: func.isRequired,
    isLoadingCourses: bool.isRequired,
    onSelectedChanged: func,
    detailsRef: func,
    isExpanded: bool,
  }

  static defaultProps = {
    detailsRef: () => {},
    onSelectedChanged: () => {},
    isExpanded: true,
  }

  constructor (props) {
    super(props)
    this.state = {
      isExpanded: props.isExpanded,
      announceChanges: false,
    }
    this._homeRef = null;
  }

  componentDidMount () {
    this.fixIcons()
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

  componentDidUpdate () {
    this.fixIcons()
  }

  onFilterActivate = () => {
    this.setState({
      isExpanded: true,
    })
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

  // when user clicks "Courses" button to toggle visibliity
  onToggleCoursePicker = (event, isExpanded) => {
    this.setState({isExpanded})
  }

  // in IE, instui icons are in the tab order and get focus, even if hidden
  // this fixes them up so that doesn't happen.
  // Eventually this should get folded into instui via INSTUI-572
  fixIcons () {
    if (this._homeRef) {
      Array.prototype.forEach.call(
        this._homeRef.querySelectorAll('svg[aria-hidden]'),
        (el) => { el.setAttribute('focusable', 'false') }
      )
    }
  }

  reloadCourses () {
    this.props.loadCourses(this.state.filters)
  }

  render () {
    return (
      <div className="bca-course-picker" ref={(el) => { this._homeRef = el }}>
        <CourseFilter
          ref={(c) => { this.filter = c }}
          terms={this.props.terms}
          subAccounts={this.props.subAccounts}
          onChange={this.onFilterChange}
          onActivate={this.onFilterActivate}
        />
        <div className="bca-course-details__wrapper">
          <ToggleDetails
            ref={(c) => { this.coursesToggle = c }}
            expanded={this.state.isExpanded}
            summary={
              <span ref={(c) => {
                if (c) this.props.detailsRef(c.parentElement.parentElement)
              }}>
                <Text>{I18n.t('Courses')}</Text>
              </span>
            }
            onToggle={this.onToggleCoursePicker}
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
