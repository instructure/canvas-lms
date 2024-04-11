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
import {View} from '@instructure/ui-view'
import {Grid} from '@instructure/ui-grid'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {useScope as useI18nScope} from '@canvas/i18n'

import * as GradeActions from '../../grades/GradeActions'
import * as StudentActions from '../../students/StudentActions'
import AcceptGradesButton from './AcceptGradesButton'

const I18n = useI18nScope('assignment_grade_summary')

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
      selectionDetails: props.bulkSelectionDetails[graderId],
    }

    return row
  })

  const showAcceptGradesColumn =
    !props.gradesLoading && rows.some(row => (row.selectionDetails || {}).allowed)

  return (
    <View as="div" padding="0 small" data-testid="graders-table">
      <ScreenReaderContent>
        <Heading>{I18n.t('Grader Details')}</Heading>
      </ScreenReaderContent>

      <Grid rowSpacing="small">
        <Grid.Row>
          <Grid.Col>
            <Text weight="bold">{I18n.t('Grader')}</Text>
          </Grid.Col>

          {showAcceptGradesColumn && (
            <Grid.Col>
              <Text weight="bold">{I18n.t('Accept Grades')}</Text>
            </Grid.Col>
          )}
        </Grid.Row>

        {rows.map(row => (
          <Grid.Row id={`grader-row-${row.graderId}`} key={row.graderId}>
            <Grid.Col>
              <label className="grader-label" htmlFor={`grader-row-accept-${row.graderId}`}>
                {row.graderName}
              </label>
            </Grid.Col>

            {showAcceptGradesColumn && (
              <Grid.Col>
                <AcceptGradesButton
                  id={`grader-row-accept-${row.graderId}`}
                  acceptGradesStatus={row.acceptGradesStatus}
                  onClick={row.onAccept}
                  selectionDetails={row.selectionDetails}
                  graderName={row.graderName}
                />
              </Grid.Col>
            )}
          </Grid.Row>
        ))}
      </Grid>
    </View>
  )
}

GradersTable.propTypes = {
  bulkSelectProvisionalGradeStatuses: shape({}).isRequired,
  bulkSelectionDetails: shape({}).isRequired,
  graders: arrayOf(
    shape({
      graderName: string,
      graderId: string.isRequired,
    })
  ).isRequired,
  gradesLoading: bool.isRequired,
}

function mapStateToProps(state) {
  const {bulkSelectProvisionalGradeStatuses, bulkSelectionDetails, provisionalGrades} = state.grades

  return {
    bulkSelectProvisionalGradeStatuses,
    bulkSelectionDetails,
    graders: state.context.graders,
    gradesLoading: state.students.loadStudentsStatus !== StudentActions.SUCCESS,
    provisionalGrades,
  }
}

function mapDispatchToProps(dispatch) {
  return {
    onGradesAccept(graderId) {
      dispatch(GradeActions.acceptGraderGrades(graderId))
    },
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(GradersTable)
