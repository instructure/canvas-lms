/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState, useCallback, useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {nanoid} from 'nanoid'
import PropTypes from 'prop-types'

import {Table} from '@instructure/ui-table'

import {GradeSummaryContext} from './context'
import {
  getGradingPeriodID,
  sortAssignments,
  listDroppedAssignments,
  filteredAssignments,
} from './utils'
import useStore, {updateState} from '../stores'
import {calculateCourseGrade} from './gradeCalculatorConversions'

import {totalRow} from './AssignmentTableRows/TotalRow'
import {assignmentGroupRow} from './AssignmentTableRows/AssignmentGroupRow'
import {gradingPeriodRow} from './AssignmentTableRows/GradingPeriodRow'
import {assignmentRow} from './AssignmentTableRows/AssignmentRow'
import {scoreDistributionRow} from './AssignmentTableRows/ScoreDistributionRow'
import {rubricRow} from './AssignmentTableRows/RubricRow'

const I18n = useI18nScope('grade_summary')

const headers = [
  {key: 'name', value: I18n.t('Name'), id: nanoid(), alignment: 'start', width: '30%'},
  {key: 'dueAt', value: I18n.t('Due Date'), id: nanoid(), alignment: 'start', width: '20%'},
  {key: 'status', value: I18n.t('Status'), id: nanoid(), alignment: 'center', width: '15%'},
  {key: 'score', value: I18n.t('Score'), id: nanoid(), alignment: 'center', width: '10%'},
]

const getCurrentOrFinalGrade = (
  allGradingPeriods,
  calculateOnlyGradedAssignments,
  current,
  final
) => {
  if (allGradingPeriods) {
    return calculateOnlyGradedAssignments ? current : final
  } else {
    return current
  }
}

const AssignmentTable = ({
  queryData,
  layout,
  handleReadStateChange,
  handleRubricReadStateChange,
  setSubmissionAssignmentId,
  submissionAssignmentId,
  hideTotalRow = false,
}) => {
  const {assignmentSortBy} = React.useContext(GradeSummaryContext)
  const [calculateOnlyGradedAssignments, setCalculateOnlyGradedAssignments] = useState(true)
  const [openAssignmentDetailIds, setOpenAssignmentDetailIds] = useState([])
  const [openRubricDetailIds, setOpenRubricDetailIds] = useState([])
  const [activeWhatIfScores, setActiveWhatIfScores] = useState([])
  const [courseGrades, setCourseGrades] = useState(
    calculateCourseGrade(
      queryData?.relevantGradingPeriodGroup,
      queryData?.assignmentGroupsConnection?.nodes,
      filteredAssignments(queryData, calculateOnlyGradedAssignments, activeWhatIfScores),
      calculateOnlyGradedAssignments,
      queryData?.applyGroupWeights,
      activeWhatIfScores
    )
  )

  useEffect(() => {
    const grades = calculateCourseGrade(
      queryData?.relevantGradingPeriodGroup,
      queryData?.assignmentGroupsConnection?.nodes,
      filteredAssignments(queryData, calculateOnlyGradedAssignments, activeWhatIfScores),
      calculateOnlyGradedAssignments,
      queryData?.applyGroupWeights,
      activeWhatIfScores
    )
    setCourseGrades(grades)
  }, [activeWhatIfScores, calculateOnlyGradedAssignments, queryData])

  const [droppedAssignments, setDroppedAssignments] = useState(
    listDroppedAssignments(queryData, getGradingPeriodID() === '0', true)
  )

  const handleCalculateOnlyGradedAssignmentsChange = useCallback(() => {
    const checked = document.querySelector('#only_consider_graded_assignments').checked
    setCalculateOnlyGradedAssignments(checked)
    setDroppedAssignments(listDroppedAssignments(queryData, getGradingPeriodID() === '0', checked))
  }, [queryData])

  useEffect(() => {
    const checkbox = document.querySelector('#only_consider_graded_assignments')
    if (checkbox) {
      checkbox.addEventListener('change', handleCalculateOnlyGradedAssignmentsChange)
    }
    return () => {
      if (checkbox) {
        checkbox.removeEventListener('change', handleCalculateOnlyGradedAssignmentsChange)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const open = useStore(state => state.submissionTrayOpen)

  const setShowTray = () => {
    const newState = !open
    if (!newState) {
      setSubmissionAssignmentId('')
    }
    updateState({submissionTrayOpen: newState})
  }

  return (
    <Table caption={I18n.t('Student Grade Summary')} layout={layout} hover={true}>
      <Table.Head>
        <Table.Row>
          {(headers || []).map(header => (
            <Table.ColHeader
              key={header?.key}
              id={header?.id}
              textAlign={header?.alignment}
              width={header?.width}
            >
              {header?.value}
            </Table.ColHeader>
          ))}
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {sortAssignments(assignmentSortBy, queryData?.assignmentsConnection?.nodes)
          ?.map(assignment => {
            const modifiedAssignment = {
              ...assignment,
              dropped: droppedAssignments.includes(assignment),
            }

            return [
              assignmentRow(
                modifiedAssignment,
                queryData,
                setShowTray,
                handleReadStateChange,
                handleRubricReadStateChange,
                setOpenAssignmentDetailIds,
                openAssignmentDetailIds,
                setSubmissionAssignmentId,
                submissionAssignmentId,
                setOpenRubricDetailIds,
                openRubricDetailIds,
                setActiveWhatIfScores,
                activeWhatIfScores
              ),
              openAssignmentDetailIds.includes(modifiedAssignment._id) &&
              modifiedAssignment?.scoreStatistic
                ? scoreDistributionRow(
                    modifiedAssignment,
                    setOpenAssignmentDetailIds,
                    openAssignmentDetailIds
                  )
                : null,
              openRubricDetailIds.includes(modifiedAssignment._id) && modifiedAssignment.rubric
                ? rubricRow(assignment, setOpenRubricDetailIds, openRubricDetailIds)
                : null,
            ]
          })
          .flat()}
        {getGradingPeriodID() !== '0'
          ? queryData?.assignmentGroupsConnection?.nodes?.map(assignmentGroup => {
              return assignmentGroupRow(
                assignmentGroup,
                queryData,
                calculateOnlyGradedAssignments,
                calculateOnlyGradedAssignments
                  ? courseGrades?.assignmentGroups[assignmentGroup._id]?.current
                  : courseGrades?.assignmentGroups[assignmentGroup._id]?.current
              )
            })
          : queryData?.gradingPeriodsConnection?.nodes?.map(gradingPeriod => {
              return gradingPeriod.displayTotals
                ? gradingPeriodRow(
                    gradingPeriod,
                    queryData,
                    calculateOnlyGradedAssignments,
                    calculateOnlyGradedAssignments
                      ? courseGrades?.gradingPeriods[gradingPeriod._id].current
                      : courseGrades?.gradingPeriods[gradingPeriod._id].current
                  )
                : null
            })}
        {!hideTotalRow && totalRow(
          queryData,
          calculateOnlyGradedAssignments,
          getCurrentOrFinalGrade(
            getGradingPeriodID() === '0',
            calculateOnlyGradedAssignments,
            courseGrades?.current,
            courseGrades?.final,
            activeWhatIfScores
          )
        )}
      </Table.Body>
    </Table>
  )
}

AssignmentTable.propTypes = {
  queryData: PropTypes.object,
  layout: PropTypes.string,
  handleReadStateChange: PropTypes.func,
  setSubmissionAssignmentId: PropTypes.func,
  submissionAssignmentId: PropTypes.string,
}

export default AssignmentTable
