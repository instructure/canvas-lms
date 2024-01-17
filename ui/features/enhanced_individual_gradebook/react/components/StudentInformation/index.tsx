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

import React, {useEffect, useMemo, useState} from 'react'
import {View} from '@instructure/ui-view'
import {getFinalGradeOverrides} from '@canvas/grading/FinalGradeOverrideApi'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import type {
  AssignmentGroupCriteriaMap,
  FinalGradeOverrideMap,
  FinalGradeOverride,
} from '@canvas/grading/grading.d'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Text} from '@instructure/ui-text'
import {IconWarningLine} from '@instructure/ui-icons'
import {
  type GradebookOptions,
  type GradebookStudentDetails,
  type GradebookUserSubmissionDetails,
  ApiCallStatus,
} from '../../../types'
import Notes from './Notes'
import {useGradebookNotes} from '../../hooks/useGradebookNotes'
import FinalGradeOverrideContainer from './FinalGradeOverrideContainer'
import {
  calculateGradesForStudent,
  getLetterGrade,
  scoreToPercentage,
  scoreToScaledPoints,
} from '../../../utils/gradebookUtils'
import {GradingPeriodScores} from './GradingPeriodScores'
import {AssignmentGroupScores} from './AssignmentGroupScores'
import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  student?: GradebookStudentDetails
  submissions?: GradebookUserSubmissionDetails[]
  assignmentGroupMap: AssignmentGroupCriteriaMap
  studentNotesColumnId?: string | null
  gradebookOptions: GradebookOptions
  currentStudentHiddenName: string
  invalidAssignmentGroups: Record<string, string>
}

export default function StudentInformation({
  assignmentGroupMap,
  studentNotesColumnId,
  gradebookOptions,
  student,
  submissions,
  currentStudentHiddenName,
  invalidAssignmentGroups,
}: Props) {
  const {
    customOptions: {
      allowFinalGradeOverride,
      includeUngradedAssignments,
      hideStudentNames,
      showNotesColumn,
    },
    customColumnsUrl,
    customColumnDataUrl,
    customColumnDatumUrl,
    contextId,
    contextUrl,
    finalGradeOverrideEnabled,
    gradeCalcIgnoreUnpostedAnonymousEnabled,
    gradingPeriodSet,
    gradingStandard,
    gradingStandardScalingFactor,
    gradingStandardPointsBased,
    groupWeightingScheme,
    selectedGradingPeriodId,
  } = gradebookOptions

  const [finalGradeOverrides, setFinalGradeOverrides] = useState<FinalGradeOverrideMap>({})
  const {submitNotesError, submitNotesStatus, studentNotes, getNotesStatus, submit} =
    useGradebookNotes(
      studentNotesColumnId,
      customColumnsUrl,
      customColumnDataUrl,
      customColumnDatumUrl
    )

  useEffect(() => {
    if (submitNotesError && submitNotesStatus === ApiCallStatus.FAILED) {
      showFlashError(I18n.t('Error updating notes'))(new Error(submitNotesError))
    }
  }, [submitNotesError, submitNotesStatus])

  useEffect(() => {
    async function fetchFinalGradeOverrides() {
      if (!contextId) {
        return
      }
      const data = await getFinalGradeOverrides(contextId)
      if (!data) {
        return // TODO: handle error
      }
      setFinalGradeOverrides(data.finalGradeOverrides)
    }
    fetchFinalGradeOverrides()
  }, [contextId])

  const filteredSubmissions = selectedGradingPeriodId
    ? submissions?.filter(s => s.gradingPeriodId === selectedGradingPeriodId)
    : submissions

  const studentGradeResults = useMemo(
    () =>
      calculateGradesForStudent({
        submissions: filteredSubmissions,
        assignmentGroupMap,
        groupWeightingScheme,
        gradeCalcIgnoreUnpostedAnonymousEnabled,
        gradingPeriodSet,
        studentId: student?.id,
      }),
    [
      filteredSubmissions,
      assignmentGroupMap,
      groupWeightingScheme,
      gradeCalcIgnoreUnpostedAnonymousEnabled,
      gradingPeriodSet,
      student,
    ]
  )

  if (!student || !submissions || !studentGradeResults) {
    return (
      <View as="div" data-testid="student-information-empty">
        <View as="div" className="row-fluid">
          <View as="div" className="span4">
            <View as="h2">{I18n.t('Student Information')}</View>
          </View>
          <View as="div" className="span8 pad-box top-only">
            <View as="p" className="submission_selection">
              {I18n.t('Select a student to view additional information here.')}
            </View>
          </View>
        </View>
      </View>
    )
  }

  const {current, final, assignmentGroups, gradingPeriods = {}} = studentGradeResults

  const gradeToDisplay = includeUngradedAssignments ? final : current
  const finalGradePercent = gradeToDisplay
    ? scoreToPercentage(gradeToDisplay.score, gradeToDisplay.possible)
    : null
  const currentStudentNotes = studentNotes[student.id] ?? ''
  const showGradingPeriodSubtotals = !selectedGradingPeriodId && gradingPeriodSet?.weighted

  const renderFinalGradeText = () => {
    const {possible, score} = gradeToDisplay
    if (possible === null || possible === undefined) {
      return '-'
    }

    let displayAsScaledPoints = false
    let finalGradeText = ''

    if (gradingStandard) {
      displayAsScaledPoints = gradingStandardPointsBased
      const scalingFactor = gradingStandardScalingFactor

      if (displayAsScaledPoints && possible) {
        const scaledPossible = I18n.n(scalingFactor, {
          precision: 1,
        })
        const scaledScore = I18n.n(scoreToScaledPoints(score, possible, scalingFactor), {
          precision: 1,
        })

        finalGradeText = `${scaledScore} / ${scaledPossible}`
      } else {
        finalGradeText = Number.isNaN(Number(finalGradePercent)) ? '-' : `${finalGradePercent}%`
      }
    } else {
      finalGradeText = Number.isNaN(Number(finalGradePercent)) ? '-' : `${finalGradePercent}%`
    }

    // TODO: refactor hidePointsText & showPointsText after tests are in place
    const hidePointsText = !!(
      groupWeightingScheme === 'percent' ||
      (!selectedGradingPeriodId && gradingPeriodSet?.weighted)
    )
    const showPointsText = !!(!hidePointsText && gradeToDisplay)
    const pointsText = showPointsText
      ? ` (${gradeToDisplay.score} / ${gradeToDisplay.possible} ${I18n.t('points')})`
      : ''

    const letterGradeText = gradingStandard
      ? ` - ${GradeFormatHelper.replaceDashWithMinus(
          getLetterGrade(possible, score, gradingStandard)
        )}`
      : ''

    return `${finalGradeText}${pointsText}${letterGradeText}`
  }

  const studentUrl = `${contextUrl}/grades/${student.id}`
  const invalidAssignmentGroupsLength = Object.keys(invalidAssignmentGroups).length
  const invalidAssignmentGroupsNames = Object.values(invalidAssignmentGroups)
  const showInvalidAssignmentGroupsWarning =
    invalidAssignmentGroupsLength > 0 && groupWeightingScheme === 'percent'
  const invalidGroupsWarningPhrases = () => {
    return I18n.t(
      'invalid_group_warning',
      {
        one: 'Note: Score does not include assignments from the group %{list_of_group_names} because it has no points possible.',
        other:
          'Note: Score does not include assignments from the groups %{list_of_group_names} because they have no points possible.',
      },
      {
        count: invalidAssignmentGroupsLength,
        list_of_group_names: invalidAssignmentGroupsNames.join(' or '),
      }
    )
  }

  return (
    <View as="div">
      <View as="div" className="row-fluid">
        <View as="div" className="span4">
          <View as="h2">{I18n.t('Student Information')}</View>
        </View>
        <View as="div" className="span8">
          <View as="h3" className="student_selection" data-testid="student-information-name">
            {hideStudentNames ? (
              currentStudentHiddenName
            ) : (
              <Link isWithinText={false} href={studentUrl}>
                {student.name}
              </Link>
            )}
          </View>

          <View as="div">
            <View as="strong">
              {I18n.t('Secondary ID:')}
              <View as="span" className="secondary_id" data-testid="secondary-id">
                {' '}
                {hideStudentNames ? <View as="em">{I18n.t('hidden')}</View> : student.loginId}
              </View>
            </View>
          </View>
          <View as="div">
            <View as="strong">
              {I18n.t('Sections: ')}
              {student.enrollments.map(enrollment => enrollment.section.name).join(', ')}
            </View>
          </View>
          {showNotesColumn && (
            <Notes
              currentStudentNotes={currentStudentNotes}
              disabled={
                getNotesStatus === ApiCallStatus.PENDING ||
                submitNotesStatus === ApiCallStatus.PENDING
              }
              handleSubmitNotes={notes => submit(notes, student.id)}
            />
          )}
          <View as="h4">{I18n.t('Grades')}</View>
          <View as="div" className="ic-Table-responsive-x-scroll">
            <table className="ic-Table">
              <thead>
                <tr>
                  <th scope="col">
                    {showGradingPeriodSubtotals
                      ? I18n.t('Grading Period')
                      : I18n.t('Assignment Group')}
                  </th>
                  <th scope="col">{I18n.t('Grade')}</th>
                  <th scope="col">{I18n.t('Letter Grade')}</th>
                  <th scope="col">{I18n.t('% of Grade')}</th>
                </tr>
              </thead>
              <tbody>
                {showGradingPeriodSubtotals
                  ? Object.keys(gradingPeriods).map(gradingPeriodId => (
                      <GradingPeriodScores
                        key={`grading_period_scores_${gradingPeriodId}`}
                        gradingPeriodId={gradingPeriodId}
                        gradingPeriodSet={gradingPeriodSet}
                        gradingPeriods={gradingPeriods}
                        gradingScheme={{
                          data: gradingStandard || [],
                          pointsBased: gradingStandardPointsBased,
                          scalingFactor: gradingStandardScalingFactor,
                        }}
                        includeUngradedAssignments={includeUngradedAssignments}
                      />
                    ))
                  : Object.keys(assignmentGroupMap).map(assignmentGroupId => (
                      <AssignmentGroupScores
                        key={`assignment_group_scores_${assignmentGroupId}`}
                        assignmentGroupId={assignmentGroupId}
                        assignmentGroupMap={assignmentGroupMap}
                        assignmentGroups={assignmentGroups}
                        gradingScheme={{
                          data: gradingStandard || [],
                          pointsBased: gradingStandardPointsBased,
                          scalingFactor: gradingStandardScalingFactor,
                        }}
                        includeUngradedAssignments={includeUngradedAssignments}
                      />
                    ))}
              </tbody>
            </table>
          </View>

          <View as="h3">
            {I18n.t('Final Grade: ')}
            <View as="span" className="total-grade">
              {renderFinalGradeText()}
            </View>
          </View>
          {finalGradeOverrideEnabled && allowFinalGradeOverride && (
            <FinalGradeOverrideContainer
              finalGradeOverride={finalGradeOverrides[student.id]}
              enrollmentId={student.enrollments[0]?.id}
              onSubmit={(finalGradeOverride: FinalGradeOverride) => {
                setFinalGradeOverrides({
                  ...finalGradeOverrides,
                  [student.id]: finalGradeOverride,
                })
              }}
              gradingScheme={{
                data: gradingStandard || [],
                pointsBased: gradingStandardPointsBased,
                scalingFactor: gradingStandardScalingFactor,
              }}
              gradingPeriodId={selectedGradingPeriodId}
            />
          )}

          {showInvalidAssignmentGroupsWarning && (
            <View as="div" className="text-error" margin="small 0 0 0" style={{width: '100%'}}>
              <Text size="medium" data-testid="no-points-possible-warning">
                <IconWarningLine /> {invalidGroupsWarningPhrases()}{' '}
              </Text>
            </View>
          )}
        </View>
      </View>
    </View>
  )
}
