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

import React from 'react'
import {connect} from 'react-redux'
import {arrayOf, bool, shape, string} from 'prop-types'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!assignment_grade_summary'

import * as GradeActions from '../../grades/GradeActions'
import * as StudentActions from '../../students/StudentActions'
import AcceptGradesButton from './AcceptGradesButton'

function GradersTable(props) {
  const rows = props.graders.map(grader => {
    const {graderId, graderName} = grader

    const row = {
      acceptGradesStatus: props.bulkSelectProvisionalGradeStatuses[graderId],
      graderId,
      graderName,
      onAccept() {
        props.onGradesAccept(graderId)
      },
      selectionDetails: props.bulkSelectionDetails[graderId]
    }

    return row
  })

  const showAcceptGradesColumn =
    !props.gradesLoading && rows.some(row => (row.selectionDetails || {}).allowed)

  return (
    <View as="table" role="table">
      <caption>
        {<ScreenReaderContent>{I18n.t('Grader Details Table')}</ScreenReaderContent>}
      </caption>

      <thead>
        <tr role="row">
          <View as="th" padding="x-small small" role="columnheader" scope="col" textAlign="start">
            {I18n.t('Grader')}
          </View>

          {showAcceptGradesColumn && (
            <View as="th" padding="x-small small" role="columnheader" scope="col" textAlign="start">
              {I18n.t('Accept Grades')}
            </View>
          )}
        </tr>
      </thead>

      <tbody>
        {rows.map(row => (
          <tr id={`grader-row-${row.graderId}`} key={row.graderId} role="row">
            <View as="th" padding="xxx-small small" role="rowheader" scope="row" textAlign="start">
              <View as="div" padding="xx-small none">
                <Text weight="normal">{row.graderName}</Text>
              </View>
            </View>

            {showAcceptGradesColumn && (
              <View as="td" padding="xxx-small small" role="cell">
                <AcceptGradesButton
                  acceptGradesStatus={row.acceptGradesStatus}
                  onClick={row.onAccept}
                  selectionDetails={row.selectionDetails}
                  graderName={row.graderName}
                />
              </View>
            )}
          </tr>
        ))}
      </tbody>
    </View>
  )
}

GradersTable.propTypes = {
  bulkSelectProvisionalGradeStatuses: shape({}).isRequired,
  bulkSelectionDetails: shape({}).isRequired,
  graders: arrayOf(
    shape({
      graderName: string,
      graderId: string.isRequired
    })
  ).isRequired,
  gradesLoading: bool.isRequired
}

function mapStateToProps(state) {
  const {bulkSelectProvisionalGradeStatuses, bulkSelectionDetails, provisionalGrades} = state.grades

  return {
    bulkSelectProvisionalGradeStatuses,
    bulkSelectionDetails,
    graders: state.context.graders,
    gradesLoading: state.students.loadStudentsStatus !== StudentActions.SUCCESS,
    provisionalGrades
  }
}

function mapDispatchToProps(dispatch) {
  return {
    onGradesAccept(graderId) {
      dispatch(GradeActions.acceptGraderGrades(graderId))
    }
  }
}

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(GradersTable)
