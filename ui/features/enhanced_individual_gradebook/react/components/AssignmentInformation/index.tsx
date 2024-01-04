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

import React, {useCallback, useMemo, useState} from 'react'
import {intersection, some} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconWarningLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import type {
  AssignmentConnection,
  GradebookOptions,
  SortableStudent,
  SubmissionConnection,
  SubmissionGradeChange,
} from '../../../types'
import {
  computeAssignmentDetailText,
  disableGrading,
  isInPastGradingPeriodAndNotAdmin,
} from '../../../utils/gradebookUtils'
import MessageStudentsWhoModal from './MessageStudentsWhoModal'
import DefaultGradeModal from './DefaultGradeModal'
import {CurveGradesModal} from './CurveGradesModal'
import SubmissionDownloadModal from './SubmissionDownloadModal'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('enhanced_individual_gradebook')

export type AssignmentInformationComponentProps = {
  assignment?: AssignmentConnection
  assignmentGroupInvalid?: boolean
  students?: SortableStudent[]
  submissions?: SubmissionConnection[]
  gradebookOptions: GradebookOptions
  handleSetGrades: (updatedSubmissions: SubmissionGradeChange[]) => void
}

export default function AssignmentInformation({
  assignment,
  assignmentGroupInvalid,
  gradebookOptions,
  students = [],
  submissions = [],
  handleSetGrades,
}: AssignmentInformationComponentProps) {
  const {gradedSubmissions, scores} = useMemo(
    () => ({
      gradedSubmissions: submissions.filter(s => s.score !== null && s.score !== undefined),
      scores: submissions.map(s => s.score ?? 0),
    }),
    [submissions]
  )

  if (!assignment) {
    return (
      <View as="div" data-testid="assignment-information-empty">
        <View as="div" className="row-fluid">
          <View as="div" className="span4">
            <View as="h2">{I18n.t('Assignment Information')}</View>
          </View>
          <View as="div" className="span8 pad-box top-only">
            <View as="p" className="submission_selection">
              {I18n.t('Select an assignment to view additional information here.')}
            </View>
          </View>
        </View>
      </View>
    )
  }

  const {downloadAssignmentSubmissionsUrl, contextUrl, groupWeightingScheme} = gradebookOptions
  const downloadSubmissionsUrl = (downloadAssignmentSubmissionsUrl ?? '').replace(
    ':assignment',
    assignment.id
  )
  const {hasSubmittedSubmissions, submissionTypes, htmlUrl} = assignment
  const showSubmissionDownloadButton = () => {
    const allowList = ['online_upload', 'online_text_entry', 'online_url']
    const submissionTypesOnAllowlist = intersection(submissionTypes, allowList)
    return hasSubmittedSubmissions && some(submissionTypesOnAllowlist)
  }

  const translatedSubmissionTypes: {[key: string]: any} = {
    discussion_topic: I18n.t('Discussion topic'),
    online_quiz: I18n.t('Online quiz'),
    on_paper: I18n.t('On paper'),
    none: I18n.t('None'),
    external_tool: I18n.t('External tool'),
    online_text_entry: I18n.t('Online text entry'),
    online_url: I18n.t('Online URL'),
    online_upload: I18n.t('Online upload'),
    media_recording: I18n.t('Media recording'),
    student_annotation: I18n.t('Student annotation'),
  }

  const readableSubmissionTypes = submissionTypes
    ?.map(snakeCase => translatedSubmissionTypes[snakeCase])
    .join(', ')

  const speedGraderUrl = () => {
    return `${contextUrl}/gradebook/speed_grader?assignment_id=${assignment.id}`
  }

  const showAssignmentPointsWarning = (): boolean => {
    return (assignmentGroupInvalid ?? false) && groupWeightingScheme === 'percent'
  }

  return (
    <View as="div" data-testid="assignment-information">
      <View as="div" className="row-fluid">
        <View as="div" className="span4">
          <View as="h2">Assignment Information</View>
        </View>
        <View as="div" className="span8">
          <View as="h3" className="assignment_selection">
            <Link href={htmlUrl} isWithinText={false} data-testid="assignment-information-name">
              {assignment.name}
            </Link>
          </View>
          {assignment.omitFromFinalGrade ? (
            <>
              <i className="icon-warning">
                <View as="span" className="screenreader-only">
                  {I18n.t('Warning')}
                </View>
              </i>{' '}
              {I18n.t('This assignment does not count toward the final grade.')}
            </>
          ) : showAssignmentPointsWarning() ? (
            <View as="span" className="text-error">
              <Link
                href={htmlUrl}
                isWithinText={false}
                renderIcon={<IconWarningLine size="x-small" />}
                data-testid="assignment-group-no-points-warning"
              >
                <ScreenReaderContent>Warning</ScreenReaderContent>
                Assignments in this group have no points possible and cannot be included in grade
                calculation.
              </Link>
            </View>
          ) : null}
          <View as="div">
            <Link
              href={speedGraderUrl()}
              isWithinText={false}
              data-testid="assignment-speedgrader-link"
            >
              {I18n.t('See this assignment in speedgrader')}
            </Link>
          </View>
          {showSubmissionDownloadButton() && (
            <View as="div" margin="small 0 0 0">
              <SubmissionDownloadModal downloadSubmissionsUrl={downloadSubmissionsUrl} />
            </View>
          )}
          <View as="div" className="pad-box no-sides" data-testid="assignment-submission-info">
            <View as="p">
              <View as="strong">
                {I18n.t('Submission types:')} {readableSubmissionTypes}
              </View>
            </View>
            <View as="p">
              <View as="strong">
                {I18n.t('Graded submissions:')} {gradedSubmissions.length}
              </View>
            </View>
          </View>

          <AssignmentScoreDetails assignment={assignment} scores={scores} />

          <AssignmentActions
            assignment={assignment}
            submissions={submissions}
            students={students}
            gradebookOptions={gradebookOptions}
            handleSetGrades={handleSetGrades}
          />
        </View>
      </View>
    </View>
  )
}

type AssignmentScoreDetailsProps = {
  assignment: AssignmentConnection
  scores: number[]
}
function AssignmentScoreDetails({assignment, scores}: AssignmentScoreDetailsProps) {
  const {average, max, min} = useMemo(
    () => computeAssignmentDetailText(assignment, scores),
    [assignment, scores]
  )
  return (
    <View as="div" className="pad-box bottom-only ic-Table-responsive-x-scroll">
      <table className="ic-Table">
        <thead>
          <tr>
            <th>{I18n.t('Points possible')}</th>
            <th>{I18n.t('Average Score')}</th>
            <th>{I18n.t('High Score')}</th>
            <th>{I18n.t('Low Score')}</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td data-testid="assignment-points-possible">
              {assignment.pointsPossible ? assignment.pointsPossible : I18n.t('No points possible')}
            </td>
            <td data-testid="assignment-average">{average}</td>
            <td data-testid="assignment-max">{max}</td>
            <td data-testid="assignment-min">{min}</td>
          </tr>
        </tbody>
      </table>
    </View>
  )
}

type AssignmentActionsProps = {
  assignment: AssignmentConnection
  students: SortableStudent[]
  submissions: SubmissionConnection[]
  gradebookOptions: GradebookOptions
  handleSetGrades: (updatedSubmissions: SubmissionGradeChange[]) => void
}
function AssignmentActions({
  assignment,
  students,
  submissions,
  gradebookOptions,
  handleSetGrades,
}: AssignmentActionsProps) {
  const [showMessageStudentsWhoModal, setShowMessageStudentsWhoModal] = useState(false)
  const [showSetDefaultGradeModal, setShowSetDefaultGradeModal] = useState(false)

  const onSetGrades = useCallback(
    (updatedSubmissions: SubmissionGradeChange[]) => {
      setShowSetDefaultGradeModal(false)
      if (updatedSubmissions.length) {
        handleSetGrades(updatedSubmissions)
      }
    },
    [handleSetGrades]
  )

  return (
    <>
      {!gradebookOptions.customOptions.hideStudentNames && !assignment.anonymizeStudents && (
        <View as="div" className="pad-box no-sides">
          <Button
            color="secondary"
            onClick={() => setShowMessageStudentsWhoModal(true)}
            data-testid="message-students-who-button"
          >
            {I18n.t('Message students who...')}
          </Button>
          <MessageStudentsWhoModal
            assignment={assignment}
            gradebookOptions={gradebookOptions}
            students={students}
            submissions={submissions}
            isOpen={showMessageStudentsWhoModal}
            onClose={() => setShowMessageStudentsWhoModal(false)}
          />
        </View>
      )}
      <View as="div" className="pad-box no-sides">
        <>
          <Button
            color="secondary"
            onClick={() => setShowSetDefaultGradeModal(true)}
            data-testid="default-grade-button"
            disabled={disableGrading(assignment)}
          >
            {I18n.t('Set default grade')}
          </Button>
          <DefaultGradeModal
            assignment={assignment}
            gradebookOptions={gradebookOptions}
            submissions={submissions}
            modalOpen={showSetDefaultGradeModal}
            handleClose={() => setShowSetDefaultGradeModal(false)}
            handleSetGrades={onSetGrades}
          />
        </>
        {isInPastGradingPeriodAndNotAdmin(assignment) && (
          <View padding="0 0 0 xx-small">
            <Text data-testid="default-grade-warning">
              {I18n.t(
                'Unable to set default grade because this assignment is due in a closed grading period for at least one student'
              )}
            </Text>
          </View>
        )}
      </View>
      <View as="div" className="pad-box no-sides">
        {assignment.pointsPossible ? (
          <CurveGradesModal
            assignment={assignment}
            submissions={submissions}
            handleGradeChange={onSetGrades}
            contextUrl={gradebookOptions.contextUrl}
          />
        ) : null}
        {isInPastGradingPeriodAndNotAdmin(assignment) && (
          <View padding="0 0 0 xx-small">
            <Text data-testid="curve-grade-warning">
              {I18n.t(
                'Unable to curve grades because this assignment is due in a closed grading period for at least one student'
              )}
            </Text>
          </View>
        )}
      </View>
    </>
  )
}
