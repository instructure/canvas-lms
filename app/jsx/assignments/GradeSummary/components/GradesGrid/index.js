/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, {Component} from 'react'
import {arrayOf, bool, func, shape, string} from 'prop-types'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!assignment_grade_summary'

import {speedGraderUrl} from '../../assignment/AssignmentApi'
import FocusableView from '../FocusableView'
import Grid from './Grid'
import PageNavigation from './PageNavigation'

const ROWS_PER_PAGE = 20

function studentToRow(student, pageStart, studentIndex, rowOptions) {
  const {anonymousStudents, assignmentId, courseId} = rowOptions
  return {
    speedGraderUrl: speedGraderUrl(courseId, assignmentId, {
      anonymousStudents,
      studentId: student.id
    }),
    studentId: student.id,
    studentName:
      student.displayName ||
      I18n.t('Student %{studentNumber}', {studentNumber: I18n.n(pageStart + studentIndex + 1)})
  }
}

function studentsToPages(props) {
  const {anonymousStudents, assignment, students} = props
  const rowOptions = {anonymousStudents, assignmentId: assignment.id, courseId: assignment.courseId}

  const pages = []
  for (let pageStart = 0; pageStart < students.length; pageStart += ROWS_PER_PAGE) {
    const pageStudents = students.slice(pageStart, pageStart + ROWS_PER_PAGE)
    pages.push(
      pageStudents.map((student, studentIndex) =>
        studentToRow(student, pageStart, studentIndex, rowOptions)
      )
    )
  }
  return pages
}

export default class GradesGrid extends Component {
  static propTypes = {
    /* eslint-disable react/no-unused-prop-types */
    anonymousStudents: bool.isRequired,
    assignment: shape({
      courseId: string.isRequired,
      id: string.isRequired
    }).isRequired,
    /* eslint-enable react/no-unused-prop-types */
    disabledCustomGrade: bool.isRequired,
    finalGrader: shape({
      graderId: string.isRequired
    }),
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired
      })
    ).isRequired,
    grades: shape({}).isRequired,
    onGradeSelect: func,
    selectProvisionalGradeStatuses: shape({}).isRequired,
    students: arrayOf(
      shape({
        displayName: string,
        id: string.isRequired
      }).isRequired
    ).isRequired
  }

  static defaultProps = {
    finalGrader: null,
    onGradeSelect: null
  }

  constructor(props) {
    super(props)

    this.setPage = this.setPage.bind(this)

    this.state = {
      currentPageIndex: 0,
      pages: studentsToPages(props)
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.students !== this.props.students) {
      const pages = studentsToPages(nextProps)
      const currentPageIndex = Math.min(this.state.currentPageIndex, pages.length - 1)
      this.setState({currentPageIndex, pages})
    }
  }

  setPage(page) {
    this.setState({currentPageIndex: page - 1})
  }

  render() {
    const rows = this.state.pages[this.state.currentPageIndex]

    return (
      <div>
        <FocusableView>
          {props => (
            <Grid
              disabledCustomGrade={this.props.disabledCustomGrade}
              finalGrader={this.props.finalGrader}
              graders={this.props.graders}
              grades={this.props.grades}
              horizontalScrollRef={props.horizontalScrollRef}
              onGradeSelect={this.props.onGradeSelect}
              rows={rows}
              selectProvisionalGradeStatuses={this.props.selectProvisionalGradeStatuses}
            />
          )}
        </FocusableView>

        {this.state.pages.length > 1 && (
          <View as="div" margin="medium">
            <PageNavigation
              currentPage={this.state.currentPageIndex + 1}
              onPageClick={this.setPage}
              pageCount={this.state.pages.length}
            />
          </View>
        )}
      </div>
    )
  }
}
