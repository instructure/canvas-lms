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

import PropTypes from 'prop-types'
import React from 'react'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import SelectMenu from './SelectMenu'

const I18n = createI18nScope('grade_summary')

class SelectMenuGroup extends React.Component {
  static propTypes = {
    assignmentSortOptions: PropTypes.arrayOf(PropTypes.array).isRequired,
    courses: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        nickname: PropTypes.string.isRequired,
        url: PropTypes.string.isRequired,
        gradingPeriodSetId: PropTypes.string,
      }),
    ).isRequired,
    currentUserID: PropTypes.string.isRequired,
    displayPageContent: PropTypes.func.isRequired,
    goToURL: PropTypes.func.isRequired,
    gradingPeriods: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        title: PropTypes.string.isRequired,
      }),
    ).isRequired,
    saveAssignmentOrder: PropTypes.func.isRequired,
    selectedAssignmentSortOrder: PropTypes.string.isRequired,
    selectedCourseID: PropTypes.string.isRequired,
    selectedGradingPeriodID: PropTypes.string,
    selectedStudentID: PropTypes.string.isRequired,
    students: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        name: PropTypes.string.isRequired,
        sortable_name: PropTypes.string.isRequired,
      }),
    ).isRequired,
    breakpoints: breakpointsShape,
  }

  static defaultProps = {
    selectedGradingPeriodID: null,
    breakpoints: {},
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    // @ts-expect-error
    this.onSelectAssignmentSortOrder = this.onSelection.bind(this, 'assignmentSortOrder')
    // @ts-expect-error
    this.onSelectCourse = this.onSelection.bind(this, 'courseID')
    // @ts-expect-error
    this.onSelectStudent = this.onSelection.bind(this, 'studentID')
    // @ts-expect-error
    this.onSelectGradingPeriod = this.onSelection.bind(this, 'gradingPeriodID')

    this.state = {
      assignmentSortOrder: props.selectedAssignmentSortOrder,
      courseID: props.selectedCourseID,
      gradingPeriodID: props.selectedGradingPeriodID,
      processing: false,
      studentID: props.selectedStudentID,
    }
  }

  componentDidMount() {
    // @ts-expect-error
    this.props.displayPageContent()
  }

  // @ts-expect-error
  onSelection = (state, _event, {value}) => {
    this.setState({[state]: value})
  }

  onSubmit = () => {
    this.setState({processing: true}, () => {
      // @ts-expect-error
      if (this.state.assignmentSortOrder !== this.props.selectedAssignmentSortOrder) {
        this.props
          // @ts-expect-error
          .saveAssignmentOrder(this.state.assignmentSortOrder)
          .then(this.reloadPage)
          // @ts-expect-error
          .catch(error => {
            showFlashError(I18n.t('An error occurred. Please try again.'))(error)
            this.setState({processing: false})
          })
      } else {
        this.reloadPage()
      }
    })
  }

  // @ts-expect-error
  anySelectMenuChanged(states) {
    const stateToProps = {
      assignmentSortOrder: 'selectedAssignmentSortOrder',
      courseID: 'selectedCourseID',
      gradingPeriodID: 'selectedGradingPeriodID',
      studentID: 'selectedStudentID',
    }

    // @ts-expect-error
    return states.some(state => this.state[state] !== this.props[stateToProps[state]])
  }

  gradingPeriodOptions() {
    // @ts-expect-error
    return [{id: '0', title: I18n.t('All Grading Periods')}].concat(this.props.gradingPeriods)
  }

  noSelectMenuChanged() {
    return !this.anySelectMenuChanged([
      'courseID',
      'studentID',
      'gradingPeriodID',
      'assignmentSortOrder',
    ])
  }

  reloadPage = () => {
    const {
      // @ts-expect-error
      state: {courseID: currentlySelectedCourseId},
      // @ts-expect-error
      props: {selectedCourseID: initialCourseId},
    } = this
    // @ts-expect-error
    const initialCourse = this.props.courses.find(course => course.id === initialCourseId)
    // @ts-expect-error
    const selectedCourse = this.props.courses.find(
      // @ts-expect-error
      course => course.id === currentlySelectedCourseId,
    )

    const baseURL = selectedCourse.url
    const studentURL =
      // @ts-expect-error
      this.state.studentID === this.props.currentUserID ? '' : `/${this.state.studentID}`
    let params

    if (
      selectedCourse.gradingPeriodSetId &&
      initialCourse.gradingPeriodSetId === selectedCourse.gradingPeriodSetId
    ) {
      // @ts-expect-error
      params = this.state.gradingPeriodID ? `?grading_period_id=${this.state.gradingPeriodID}` : ''
    } else {
      params = ''
    }

    // @ts-expect-error
    this.props.goToURL(`${baseURL}${studentURL}${params}`)
  }

  sortedStudents = () => {
    // @ts-expect-error
    return this.props.students.sort((a, b) => a.sortable_name.localeCompare(b.sortable_name))
  }

  render() {
    // @ts-expect-error
    const isVertical = !this.props.breakpoints.miniTablet
    return (
      <Flex alignItems={isVertical ? 'start' : 'end'} gap="small" wrap="wrap" margin="0 0 small 0">
        <Flex.Item>
          <Flex gap="small" wrap="wrap">
            {/* @ts-expect-error */}
            {this.props.students.length > 1 && (
              <Flex.Item>
                <SelectMenu
                  // @ts-expect-error
                  defaultValue={this.props.selectedStudentID}
                  disabled={this.anySelectMenuChanged(['courseID'])}
                  id="student_select_menu"
                  label={I18n.t('Student')}
                  // @ts-expect-error
                  onChange={this.onSelectStudent}
                  options={this.sortedStudents()}
                  textAttribute="name"
                  valueAttribute="id"
                />
              </Flex.Item>
            )}

            {/* @ts-expect-error */}
            {this.props.gradingPeriods.length > 0 && (
              <Flex.Item>
                <SelectMenu
                  // @ts-expect-error
                  defaultValue={this.props.selectedGradingPeriodID}
                  disabled={this.anySelectMenuChanged(['courseID'])}
                  id="grading_period_select_menu"
                  label={I18n.t('Grading Period')}
                  // @ts-expect-error
                  onChange={this.onSelectGradingPeriod}
                  options={this.gradingPeriodOptions()}
                  textAttribute="title"
                  valueAttribute="id"
                />
              </Flex.Item>
            )}

            {/* @ts-expect-error */}
            {this.props.courses.length > 1 && (
              <Flex.Item>
                <SelectMenu
                  // @ts-expect-error
                  defaultValue={this.props.selectedCourseID}
                  disabled={this.anySelectMenuChanged([
                    'studentID',
                    'gradingPeriodID',
                    'assignmentSortOrder',
                  ])}
                  id="course_select_menu"
                  label={I18n.t('Course')}
                  // @ts-expect-error
                  onChange={this.onSelectCourse}
                  // @ts-expect-error
                  options={this.props.courses}
                  textAttribute="nickname"
                  valueAttribute="id"
                />
              </Flex.Item>
            )}
            <Flex.Item>
              <SelectMenu
                // @ts-expect-error
                defaultValue={this.props.selectedAssignmentSortOrder}
                disabled={this.anySelectMenuChanged(['courseID'])}
                id="assignment_sort_order_select_menu"
                label={I18n.t('Arrange By')}
                // @ts-expect-error
                onChange={this.onSelectAssignmentSortOrder}
                // @ts-expect-error
                options={this.props.assignmentSortOptions}
                textAttribute={0}
                valueAttribute={1}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item>
          <Button
            // @ts-expect-error
            disabled={this.state.processing || this.noSelectMenuChanged()}
            id="apply_select_menus"
            onClick={this.onSubmit}
            type="submit"
            size="medium"
            color="primary"
          >
            <PresentationContent>
              <Text>{I18n.t('Apply')}</Text>
            </PresentationContent>
            <ScreenReaderContent>
              {I18n.t('Apply filters. Note: clicking this button will cause the page to reload.')}
            </ScreenReaderContent>
          </Button>
        </Flex.Item>
      </Flex>
    )
  }
}

export default WithBreakpoints(SelectMenuGroup)
