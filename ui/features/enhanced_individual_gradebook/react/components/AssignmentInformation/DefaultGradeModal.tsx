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
import React, {useCallback, useEffect, useState} from 'react'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import DefaultGradeInput from '@canvas/grading/react/DefaultGradeInput'
import {
  ApiCallStatus,
  type AssignmentConnection,
  type GradebookOptions,
  type SubmissionConnection,
  type SubmissionGradeChange,
} from '../../../types'
import {isExcused} from '@canvas/grading/GradeInputHelper'
import {useDefaultGrade, type DefaultGradeSubmissionParams} from '../../hooks/useDefaultGrade'
import {REPLY_TO_ENTRY, REPLY_TO_TOPIC} from '../GradingResults'
import {assignmentHasCheckpoints} from '../../../utils/gradeInputUtils'

const {Header: ModalHeader, Body: ModalBody} = Modal as any
const I18n = createI18nScope('enhanced_individual_gradebook')

type Props = {
  assignment: AssignmentConnection
  submissions: SubmissionConnection[]
  modalOpen: boolean
  gradebookOptions: GradebookOptions
  handleClose: () => void
  handleSetGrades: (updatedSubmissions: SubmissionGradeChange[]) => void
}

export default function DefaultGradeModal({
  assignment,
  gradebookOptions,
  modalOpen,
  submissions,
  handleClose,
  handleSetGrades,
}: Props) {
  const {contextUrl} = gradebookOptions

  const [gradeInput, setGradeInput] = useState<string>('')
  const [replyToTopicInput, setReplyToTopicInput] = useState<string>('')
  const [replyToEntryInput, setReplyToEntryInput] = useState<string>('')
  const [gradeOverwrite, setGradeOverwrite] = useState<boolean>(false)
  const {defaultGradeStatus, savedGrade, setGrades, updatedSubmissions, resetDefaultGradeStatus} =
    useDefaultGrade()

  const gradeIsMissing = (grade: string) => {
    return grade !== null && grade.toUpperCase() === 'MI'
  }

  const isCheckpointed = assignmentHasCheckpoints(assignment)

  const setGradeSuccessText = useCallback(
    (count: number): string => {
      return gradeIsMissing(savedGrade)
        ? I18n.t(
            {
              one: '1 student marked as missing',
              other: '%{count} students marked as missing',
            },
            {
              count,
            },
          )
        : I18n.t(
            {
              one: '1 student score updated',
              other: '%{count} student scores updated',
            },
            {
              count,
            },
          )
    },
    [savedGrade],
  )

  useEffect(() => {
    switch (defaultGradeStatus) {
      case ApiCallStatus.FAILED:
        showFlashError(I18n.t('Failed to set default grade'))(new Error())
        resetDefaultGradeStatus()
        break
      case ApiCallStatus.COMPLETED:
        showFlashSuccess(setGradeSuccessText(updatedSubmissions.length))()
        handleSetGrades(updatedSubmissions)
        resetDefaultGradeStatus()
        break
    }
  }, [
    defaultGradeStatus,
    handleSetGrades,
    resetDefaultGradeStatus,
    setGradeSuccessText,
    updatedSubmissions,
  ])

  const setDefaultGrade = async () => {
    if (!contextUrl) {
      return
    }

    if (!isCheckpointed) {
      if (isExcused(gradeInput)) {
        showFlashError(
          I18n.t('Default grade cannot be set to %{ex}', {
            ex: 'EX',
          }),
        )(new Error())
        return
      }

      const gradeOrMissingParam = gradeIsMissing(gradeInput)
        ? {late_policy_status: 'missing'}
        : {grade: gradeInput}
      const submissionsParams: DefaultGradeSubmissionParams = {
        submissions: {},
        dont_overwrite_grades: !gradeOverwrite,
      }
      submissions.forEach(submission => {
        submissionsParams.submissions[`submission_${submission.userId}`] = {
          assignment_id: submission.assignmentId,
          user_id: submission.userId,
          set_by_default_grade: true,
          ...gradeOrMissingParam,
        }
      })

      await setGrades(contextUrl, gradeInput, submissionsParams)
    } else {
      if (isExcused(replyToTopicInput)) {
        showFlashError(
          I18n.t('Default grade for Reply to Topic cannot be set to %{ex}', {
            ex: 'EX',
          }),
        )(new Error())
        return
      }

      if (isExcused(replyToEntryInput)) {
        showFlashError(
          I18n.t('Default grade for Required Replies cannot be set to %{ex}', {
            ex: 'EX',
          }),
        )(new Error())
        return
      }

      const setDefaultForCheckpoint = async (tag: string, input: string) => {
        const gradeOrMissingParam = () =>
          gradeIsMissing(input) ? {late_policy_status: 'missing'} : {grade: input}

        const submissionsParams: DefaultGradeSubmissionParams = {
          submissions: {},
          sub_assignment_tag: tag,
          dont_overwrite_grades: !gradeOverwrite,
        }
        submissions.forEach(submission => {
          submissionsParams.submissions[`submission_${submission.userId}`] = {
            assignment_id: submission.assignmentId,
            user_id: submission.userId,
            set_by_default_grade: true,
            ...gradeOrMissingParam(),
          }
        })

        await setGrades(contextUrl, input, submissionsParams)
      }

      await setDefaultForCheckpoint(REPLY_TO_TOPIC, replyToTopicInput)
      await setDefaultForCheckpoint(REPLY_TO_ENTRY, replyToEntryInput)
    }
  }

  return (
    <Modal
      open={modalOpen}
      onDismiss={() => {}}
      size="small"
      label="Set Default Grade Modal"
      shouldCloseOnDocumentClick={false}
      themeOverride={{mediumMaxWidth: '40em'}}
    >
      <ModalHeader>
        <CloseButton
          data-testid="default-grade-close-button"
          placement="end"
          offset="small"
          onClick={() => handleClose()}
          screenReaderLabel="Close Submission Detail"
        />
        <Heading level="h3">
          {I18n.t('Default Grade for')} {assignment.name}
        </Heading>
      </ModalHeader>
      <ModalBody padding="none">
        <View as="div" margin="medium">
          {assignment.gradingType === 'percent' ? (
            <Text>
              {I18n.t('Give all students the same')} <View as="b">{I18n.t('percent')}</View>{' '}
              {I18n.t('grade for')} <View as="i">{assignment.name}</View>{' '}
              {I18n.t('by entering and submitting a grade value below:')}
            </Text>
          ) : (
            <Text>
              {I18n.t('Give all students the same grade for')} <View as="i">{assignment.name}</View>{' '}
              {I18n.t('by entering and submitting a grade value below:')}
            </Text>
          )}
        </View>
        {!isCheckpointed && (
          <View as="div" margin="small medium">
            <DefaultGradeInput
              disabled={defaultGradeStatus === ApiCallStatus.PENDING}
              gradingType={assignment.gradingType}
              onGradeInputChange={setGradeInput}
            />
          </View>
        )}
        {isCheckpointed && (
          <Flex height="8rem" alignItems="start">
            <Flex.Item shouldShrink={true}>
              <View as="div" margin="small medium">
                <DefaultGradeInput
                  disabled={defaultGradeStatus === ApiCallStatus.PENDING}
                  gradingType={assignment.gradingType}
                  onGradeInputChange={setReplyToTopicInput}
                  header={I18n.t('Reply to Topic')}
                  outOfTextValue={
                    assignment.checkpoints &&
                    assignment.checkpoints
                      .find(cp => cp.tag === REPLY_TO_TOPIC)
                      ?.pointsPossible.toString()
                  }
                />
              </View>
            </Flex.Item>
            <Flex.Item shouldShrink={true}>
              <View as="div" margin="small medium">
                <DefaultGradeInput
                  disabled={defaultGradeStatus === ApiCallStatus.PENDING}
                  gradingType={assignment.gradingType}
                  onGradeInputChange={setReplyToEntryInput}
                  header={I18n.t('Required Replies')}
                  outOfTextValue={
                    assignment.checkpoints &&
                    assignment.checkpoints
                      .find(cp => cp.tag === REPLY_TO_ENTRY)
                      ?.pointsPossible.toString()
                  }
                />
              </View>
            </Flex.Item>
          </Flex>
        )}
        <View as="div" margin="large medium medium medium">
          <Checkbox
            label={I18n.t('Overwrite already-entered grades')}
            checked={gradeOverwrite}
            disabled={defaultGradeStatus === ApiCallStatus.PENDING}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setGradeOverwrite(e.target.checked)
            }
          />
        </View>
      </ModalBody>
      <Modal.Footer>
        <Button
          id="set-default-grade"
          data-testid="default-grade-submit-button"
          onClick={setDefaultGrade}
          type="submit"
          disabled={
            defaultGradeStatus === ApiCallStatus.PENDING ||
            (!gradeInput && (!replyToEntryInput || !replyToTopicInput))
          }
        >
          {I18n.t('Set Default Grade')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
