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
import Grid, {GridRow, GridCol} from '@instructure/ui-layout/lib/components/Grid'
import Heading from '@instructure/ui-elements/lib/components/Heading'
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
    <View as="div" padding="0 small">
      <ScreenReaderContent>
        <Heading>{I18n.t('Grader Details')}</Heading>
      </ScreenReaderContent>

      <Grid rowSpacing="small">
        <GridRow>
          <GridCol>
            <Text weight="bold">{I18n.t('Grader')}</Text>
          </GridCol>

          {showAcceptGradesColumn && (
            <GridCol>
              <Text weight="bold">{I18n.t('Accept Grades')}</Text>
            </GridCol>
          )}
        </GridRow>

        {rows.map(row => (
          <GridRow id={`grader-row-${row.graderId}`} key={row.graderId}>
            <GridCol>
              <label className="grader-label" htmlFor={`grader-row-accept-${row.graderId}`}>{row.graderName}</label>
            </GridCol>

            {showAcceptGradesColumn && (
              <GridCol>
                <AcceptGradesButton
                  id={`grader-row-accept-${row.graderId}`}
                  acceptGradesStatus={row.acceptGradesStatus}
                  onClick={row.onAccept}
                  selectionDetails={row.selectionDetails}
                  graderName={row.graderName}
                />
              </GridCol>
            )}
          </GridRow>
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
