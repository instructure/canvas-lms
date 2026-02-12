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
import {connect} from 'react-redux'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

import '@canvas/context-cards/react/StudentContextCardTrigger'
import {selectFinalGrade} from '../grades/GradeActions'
import {loadStudents} from '../students/StudentActions'
import FlashMessageHolder from './FlashMessageHolder'
import GradesGrid from './GradesGrid/index'
import Header from './Header'

const I18n = createI18nScope('assignment_grade_summary')

class Layout extends Component {
  static propTypes = {
    assignment: shape({
      courseId: string.isRequired,
      gradesPublished: bool.isRequired,
      id: string.isRequired,
    }).isRequired,
    canEditCustomGrades: bool.isRequired,
    canViewStudentIdentities: bool.isRequired,
    finalGrader: shape({
      graderId: string.isRequired,
    }),
    graders: arrayOf(
      shape({
        graderId: string.isRequired,
      }),
    ).isRequired,
    loadStudents: func.isRequired,
    provisionalGrades: shape({}).isRequired,
    selectGrade: func.isRequired,
    selectProvisionalGradeStatuses: shape({}).isRequired,
    students: arrayOf(
      shape({
        id: string.isRequired,
      }),
    ).isRequired,
  }

  static defaultProps = {
    finalGrader: null,
  }

  componentDidMount() {
    // @ts-expect-error
    this.props.loadStudents()
  }

  render() {
    // @ts-expect-error
    const onGradeSelect = this.props.assignment.gradesPublished ? null : this.props.selectGrade

    return (
      <div>
        <FlashMessageHolder />

        <Header />

        <View as="div" margin="large 0 0 0">
          {/* @ts-expect-error */}
          {this.props.students.length > 0 ? (
            <GradesGrid
              // @ts-expect-error
              anonymousStudents={!this.props.canViewStudentIdentities}
              // @ts-expect-error
              assignment={this.props.assignment}
              // @ts-expect-error
              disabledCustomGrade={!this.props.canEditCustomGrades}
              // @ts-expect-error
              finalGrader={this.props.finalGrader}
              // @ts-expect-error
              graders={this.props.graders}
              // @ts-expect-error
              grades={this.props.provisionalGrades}
              onGradeSelect={onGradeSelect}
              // @ts-expect-error
              selectProvisionalGradeStatuses={this.props.selectProvisionalGradeStatuses}
              // @ts-expect-error
              students={this.props.students}
            />
          ) : (
            <Spinner renderTitle={I18n.t('Students are loading')} />
          )}
        </View>
      </div>
    )
  }
}

// @ts-expect-error
function mapStateToProps(state) {
  const {currentUser, finalGrader, graders} = state.context
  const {assignment} = state.assignment

  const currentUserIsFinalGrader = !!finalGrader && currentUser.id === finalGrader.id

  return {
    assignment,
    canEditCustomGrades: !assignment.gradesPublished && currentUserIsFinalGrader,
    canViewStudentIdentities: currentUser.canViewStudentIdentities,
    finalGrader,
    graders,
    provisionalGrades: state.grades.provisionalGrades,
    selectProvisionalGradeStatuses: state.grades.selectProvisionalGradeStatuses,
    students: state.students.list,
  }
}

// @ts-expect-error
function mapDispatchToProps(dispatch) {
  return {
    loadStudents() {
      dispatch(loadStudents())
    },

    // @ts-expect-error
    selectGrade(gradeInfo) {
      dispatch(selectFinalGrade(gradeInfo))
    },
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Layout)
