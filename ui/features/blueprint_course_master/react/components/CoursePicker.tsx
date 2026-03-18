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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import '@canvas/rails-flash-notifications'
import propTypes from '@canvas/blueprint-courses/react/propTypes'
import CourseFilter from './CourseFilter'
import CoursePickerTable from './CoursePickerTable'
import type {Account, Course, CourseFilterFilters, Term} from '../types'

const I18n = createI18nScope('blueprint_settingsCoursePicker')

const {func, bool, arrayOf, string} = PropTypes

interface SelectionChanges {
  added: string[]
  removed: string[]
}

type FilterParams = Omit<CourseFilterFilters, 'isActive'> | CourseFilterFilters

interface CoursePickerProps {
  courses: Course[]
  terms: Term[]
  subAccounts: Account[]
  selectedCourses: string[]
  loadCourses: (filters?: FilterParams) => void
  isLoadingCourses: boolean
  onSelectedChanged?: (selected: SelectionChanges) => void
  detailsRef?: (element: {focus: () => void} | null) => void
  isExpanded?: boolean
}

interface CoursePickerState {
  isExpanded: boolean
  announceChanges: boolean
  filters?: FilterParams
}

export default class CoursePicker extends React.Component<CoursePickerProps, CoursePickerState> {
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

  _homeRef: HTMLDivElement | null = null
  filter: CourseFilter | null = null
  coursesToggle: unknown = null

  constructor(props: CoursePickerProps) {
    super(props)
    this.state = {
      isExpanded: props.isExpanded ?? true,
      announceChanges: false,
    }
    this._homeRef = null
  }

  componentDidMount() {
    this.fixIcons()
  }

  UNSAFE_componentWillReceiveProps(nextProps: CoursePickerProps) {
    if (this.state.announceChanges && !this.props.isLoadingCourses && nextProps.isLoadingCourses) {
      $.screenReaderFlashMessage(I18n.t('Loading courses started'))
    }

    if (this.state.announceChanges && this.props.isLoadingCourses && !nextProps.isLoadingCourses) {
      this.setState({announceChanges: false})
      $.screenReaderFlashMessage(
        I18n.t(
          {
            one: 'Loading courses complete: one course found',
            other: 'Loading courses complete: %{count} courses found',
          },
          {count: nextProps.courses.length},
        ),
      )
    }
  }

  componentDidUpdate() {
    this.fixIcons()
  }

  onFilterActivate = () => {
    this.setState({
      isExpanded: true,
    })
  }

  onSelectedChanged = (selected: SelectionChanges) => {
    this.props.onSelectedChanged?.(selected)
    this.setState({isExpanded: true})
  }

  // when the filter updates, load new courses
  onFilterChange = (filters: FilterParams) => {
    this.props.loadCourses(filters)

    this.setState({
      filters,
      isExpanded: true,
      announceChanges: true,
    })
  }

  // when user clicks "Courses" button to toggle visibility
  onToggleCoursePicker = (_event: unknown, isExpanded: boolean) => {
    this.setState({isExpanded})
  }

  // in IE, instui icons are in the tab order and get focus, even if hidden
  // this fixes them up so that doesn't happen.
  // Eventually this should get folded into instui via INSTUI-572
  fixIcons() {
    if (this._homeRef) {
      Array.prototype.forEach.call(this._homeRef.querySelectorAll('svg[aria-hidden]'), el => {
        el.setAttribute('focusable', 'false')
      })
    }
  }

  reloadCourses() {
    this.props.loadCourses(this.state.filters)
  }

  render() {
    return (
      <div
        className="bca-course-picker"
        ref={el => {
          this._homeRef = el
        }}
      >
        <CourseFilter
          ref={c => {
            this.filter = c
          }}
          terms={this.props.terms}
          subAccounts={this.props.subAccounts}
          onChange={this.onFilterChange}
          onActivate={this.onFilterActivate}
        />
        <div className="bca-course-details__wrapper">
          <ToggleDetails
            ref={c => {
              this.coursesToggle = c
            }}
            expanded={this.state.isExpanded}
            summary={
              <span
                ref={c => {
                  this.props.detailsRef?.(
                    (c?.parentElement?.parentElement as {focus: () => void}) ?? null,
                  )
                }}
              >
                <Text>{I18n.t('Courses')}</Text>
              </span>
            }
            onToggle={this.onToggleCoursePicker}
          >
            {this.props.isLoadingCourses && (
              <div className="bca-course-picker__loading">
                <Spinner renderTitle={I18n.t('Loading Courses')} />
              </div>
            )}
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
