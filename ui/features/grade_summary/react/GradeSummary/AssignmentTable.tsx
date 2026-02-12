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
import {useScope as createI18nScope} from '@canvas/i18n'
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

const I18n = createI18nScope('grade_summary')

// @ts-expect-error
function createHeaders(showDocumentProcessors) {
  return [
    {key: 'name', value: I18n.t('Name'), id: nanoid(), alignment: 'start', width: '30%'},
    {key: 'dueAt', value: I18n.t('Due Date'), id: nanoid(), alignment: 'start', width: '20%'},
    {key: 'status', value: I18n.t('Status'), id: nanoid(), alignment: 'center', width: '15%'},
    {key: 'score', value: I18n.t('Score'), id: nanoid(), alignment: 'center', width: '10%'},
    {
      key: 'assetReports',
      value: showDocumentProcessors ? I18n.t('Document Processors') : '',
      id: nanoid(),
      alignment: 'start',
      width: showDocumentProcessors ? null : '0',
    },
  ]
}

const getCurrentOrFinalGrade = (
  // @ts-expect-error
  allGradingPeriods,
  // @ts-expect-error
  calculateOnlyGradedAssignments,
  // @ts-expect-error
  current,
  // @ts-expect-error
  final,
) => {
  if (allGradingPeriods) {
    return calculateOnlyGradedAssignments ? current : final
  } else {
    return current
  }
}

// Returns true if there if the assignment has at least one asset processor,
// and if the assetReportsConnection.nodes is present (empty array counts as
// present for determining whether to show the column -- see
// AssetProcessorReportHelper#raw_asset_reports)
// @ts-expect-error
function assignmentHasDocumentProcessorsDataToShow(assignment) {
  const assignmentHasProcessors = !!assignment.ltiAssetProcessorsConnection?.nodes?.length
  const assignmentHasMaybeEmptyAssetReports = assignment.submissionsConnection?.nodes?.some(
    // @ts-expect-error
    sub => !!sub?.ltiAssetReportsConnection?.nodes,
  )
  return assignmentHasProcessors && assignmentHasMaybeEmptyAssetReports
}

const AssignmentTable = ({
  // @ts-expect-error
  queryData,
  // @ts-expect-error
  assignmentsData,
  // @ts-expect-error
  layout,
  // @ts-expect-error
  handleReadStateChange,
  // @ts-expect-error
  handleRubricReadStateChange,
  // @ts-expect-error
  setSubmissionAssignmentId,
  // @ts-expect-error
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
      filteredAssignments(assignmentsData, calculateOnlyGradedAssignments, activeWhatIfScores),
      calculateOnlyGradedAssignments,
      queryData?.applyGroupWeights,
      activeWhatIfScores,
    ),
  )

  const overrideGrade =
    queryData?.usersConnection?.nodes[0]?.enrollments[0]?.grades?.overrideGrade || null

  const showDocumentProcessors = assignmentsData?.assignments?.some(
    assignmentHasDocumentProcessorsDataToShow,
  )
  const headers = createHeaders(showDocumentProcessors)

  useEffect(() => {
    const grades = calculateCourseGrade(
      queryData?.relevantGradingPeriodGroup,
      queryData?.assignmentGroupsConnection?.nodes,
      filteredAssignments(assignmentsData, calculateOnlyGradedAssignments, activeWhatIfScores),
      calculateOnlyGradedAssignments,
      queryData?.applyGroupWeights,
      activeWhatIfScores,
    )
    setCourseGrades(grades)
  }, [activeWhatIfScores, assignmentsData, calculateOnlyGradedAssignments, queryData])

  const [droppedAssignments, setDroppedAssignments] = useState(
    listDroppedAssignments(queryData, assignmentsData, getGradingPeriodID() === '0', true),
  )

  const handleCalculateOnlyGradedAssignmentsChange = useCallback(() => {
    // @ts-expect-error
    const checked = document.querySelector('#only_consider_graded_assignments').checked
    setCalculateOnlyGradedAssignments(checked)
    setDroppedAssignments(
      listDroppedAssignments(queryData, assignmentsData, getGradingPeriodID() === '0', checked),
    )
  }, [assignmentsData, queryData])

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
            // @ts-expect-error
            <Table.ColHeader
              key={header.key}
              id={header.id}
              textAlign={header.alignment}
              width={header.width}
            >
              {header.value}
            </Table.ColHeader>
          ))}
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {sortAssignments(assignmentSortBy, assignmentsData?.assignments)
          ?.filter(
            // @ts-expect-error
            assignment => !ENV.SETTINGS.suppress_assignments || !assignment.suppressAssignment,
          )
          // @ts-expect-error
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
                activeWhatIfScores,
                showDocumentProcessors,
              ),
              // @ts-expect-error
              openAssignmentDetailIds.includes(modifiedAssignment._id) &&
              modifiedAssignment?.scoreStatistic
                ? scoreDistributionRow(
                    modifiedAssignment,
                    setOpenAssignmentDetailIds,
                    openAssignmentDetailIds,
                  )
                : null,
              // @ts-expect-error
              openRubricDetailIds.includes(modifiedAssignment._id) && modifiedAssignment.rubric
                ? rubricRow(assignment, setOpenRubricDetailIds, openRubricDetailIds)
                : null,
            ]
          })
          .flat()}
        {getGradingPeriodID() !== '0'
          ? // @ts-expect-error
            queryData?.assignmentGroupsConnection?.nodes?.map(assignmentGroup => {
              return assignmentGroupRow(
                assignmentGroup,
                queryData,
                assignmentsData,
                calculateOnlyGradedAssignments,
                calculateOnlyGradedAssignments
                  ? courseGrades?.assignmentGroups[assignmentGroup._id]?.current
                  : courseGrades?.assignmentGroups[assignmentGroup._id]?.current,
              )
            })
          : // @ts-expect-error
            queryData?.gradingPeriodsConnection?.nodes?.map(gradingPeriod => {
              return gradingPeriod.displayTotals
                ? gradingPeriodRow(
                    gradingPeriod,
                    queryData,
                    assignmentsData,
                    calculateOnlyGradedAssignments,
                    calculateOnlyGradedAssignments
                      ? // @ts-expect-error
                        courseGrades?.gradingPeriods[gradingPeriod._id].current
                      : // @ts-expect-error
                        courseGrades?.gradingPeriods[gradingPeriod._id].current,
                  )
                : null
            })}
        {!hideTotalRow &&
          totalRow(
            queryData,
            assignmentsData,
            calculateOnlyGradedAssignments,
            getCurrentOrFinalGrade(
              getGradingPeriodID() === '0',
              calculateOnlyGradedAssignments,
              courseGrades?.current,
              courseGrades?.final,
              // @ts-expect-error
              activeWhatIfScores,
            ),
            overrideGrade,
          )}
      </Table.Body>
    </Table>
  )
}

AssignmentTable.propTypes = {
  queryData: PropTypes.object,
  assignmentsData: PropTypes.object,
  layout: PropTypes.string,
  handleReadStateChange: PropTypes.func,
  handleRubricReadStateChange: PropTypes.func,
  setSubmissionAssignmentId: PropTypes.func,
  submissionAssignmentId: PropTypes.string,
  hideTotalRow: PropTypes.bool,
}

export default AssignmentTable
