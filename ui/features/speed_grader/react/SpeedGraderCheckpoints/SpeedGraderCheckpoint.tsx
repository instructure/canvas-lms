/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {
  type Assignment,
  REPLY_TO_ENTRY,
  REPLY_TO_TOPIC,
  type SubAssignmentSubmission,
  type SubmissionGradeParams,
  type SubmissionStatusParams,
} from './SpeedGraderCheckpointsContainer'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import type {GradeStatusUnderscore} from '@canvas/grading/accountGradingStatus'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import AssessmentGradeInput from './AssessmentGradeInput'
import {UseSameGrade} from '../Shared/UseSameGrade'

const I18n = createI18nScope('SpeedGraderCheckpoints')

export const NONE = 'none'
export const LATE = 'late'
export const MISSING = 'missing'
export const EXCUSED = 'excused'
export const EXTENDED = 'extended'

type Props = {
  assignment: Assignment
  subAssignmentSubmission: SubAssignmentSubmission
  customGradeStatusesEnabled: boolean
  customGradeStatuses?: GradeStatusUnderscore[]
  lateSubmissionInterval: string
  updateSubmissionGrade: (params: SubmissionGradeParams) => void
  updateSubmissionStatus: (params: SubmissionStatusParams) => void
  setLastSubmission: (params: SubAssignmentSubmission) => void
}

export const SpeedGraderCheckpoint = (props: Props) => {
  const standardStatuses: string[] = [NONE, LATE, MISSING, EXCUSED, EXTENDED]

  const getStatus = useCallback(() => {
    if (props.subAssignmentSubmission.excused) {
      return EXCUSED
    } else if (props.subAssignmentSubmission.missing) {
      return MISSING
    } else if (props.subAssignmentSubmission.late) {
      return LATE
    } else if (props.subAssignmentSubmission.custom_grade_status_id) {
      return props.subAssignmentSubmission.custom_grade_status_id
    } else if (
      [NONE, LATE, MISSING, EXTENDED].includes(props.subAssignmentSubmission.late_policy_status)
    ) {
      return props.subAssignmentSubmission.late_policy_status
    }

    return NONE
  }, [
    props.subAssignmentSubmission.custom_grade_status_id,
    props.subAssignmentSubmission.excused,
    props.subAssignmentSubmission.missing,
    props.subAssignmentSubmission.late,
    props.subAssignmentSubmission.late_policy_status,
  ])

  const getTimeLate = useCallback(() => {
    if (
      props.subAssignmentSubmission.late ||
      props.subAssignmentSubmission.late_policy_status === LATE
    ) {
      const secondsLate = props.subAssignmentSubmission.seconds_late
      const timeLate =
        props.lateSubmissionInterval === 'hour'
          ? Math.ceil(secondsLate / 3600).toString()
          : Math.ceil(secondsLate / (24 * 3600)).toString()

      return timeLate.toString()
    }

    return '0'
  }, [
    props.lateSubmissionInterval,
    props.subAssignmentSubmission.late,
    props.subAssignmentSubmission.late_policy_status,
    props.subAssignmentSubmission.seconds_late,
  ])

  const [status, setStatus] = useState<string>(getStatus())
  const [timeLate, setTimeLate] = useState<string>(getTimeLate())

  useEffect(() => {
    if (props.subAssignmentSubmission) {
      setStatus(getStatus())
      setTimeLate(getTimeLate())
    }
  }, [getStatus, getTimeLate, props.subAssignmentSubmission])

  const isStatusLate = status === LATE

  const getLabel = () => {
    const tag = props.subAssignmentSubmission.sub_assignment_tag

    if (tag === REPLY_TO_TOPIC) {
      return I18n.t('Reply to Topic')
    } else if (tag === REPLY_TO_ENTRY) {
      return I18n.t('Required Replies')
    } else {
      return I18n.t('Unknown Checkpoint')
    }
  }

  const updateStatus = (value: string) => {
    setStatus(value)

    let latePolicyStatus = null
    let customGradeStatusId = null

    if (standardStatuses.includes(value)) {
      latePolicyStatus = value
    } else {
      customGradeStatusId = value
    }

    props.updateSubmissionStatus({
      subAssignmentTag: props.subAssignmentSubmission.sub_assignment_tag,
      courseId: props.assignment.course_id,
      assignmentId: props.assignment.id,
      studentId: props.subAssignmentSubmission.user_id,
      latePolicyStatus: latePolicyStatus || undefined,
      customGradeStatusId: customGradeStatusId || undefined,
    })
  }

  const updateTimeLate = (value: string) => {
    const timeLate = parseInt(value, 10)
    const secondsLate =
      props.lateSubmissionInterval === 'hour' ? timeLate * 3600 : timeLate * 24 * 3600
    props.updateSubmissionStatus({
      subAssignmentTag: props.subAssignmentSubmission.sub_assignment_tag,
      courseId: props.assignment.course_id,
      assignmentId: props.assignment.id,
      studentId: props.subAssignmentSubmission.user_id,
      secondsLate,
    })
  }

  return (
    <>
      <Flex margin="none none small" gap="small" alignItems="start">
        <Flex.Item shouldShrink={true}>
          <AssessmentGradeInput
            assignment={props.assignment}
            showAlert={() => {}}
            submission={props.subAssignmentSubmission}
            courseId={props.assignment.course_id}
            updateSubmissionGrade={props.updateSubmissionGrade}
            inputDisplay="block"
            isWidthDefault={false}
            hasHeader={true}
            header={getLabel()}
            setLastSubmission={props.setLastSubmission}
          />
        </Flex.Item>
        <Flex.Item shouldShrink={true}>
          <StatusSelector
            subAssignmentTag={props.subAssignmentSubmission.sub_assignment_tag}
            status={status}
            updateStatus={updateStatus}
            customGradeStatusesEnabled={props.customGradeStatusesEnabled}
            customGradeStatuses={props.customGradeStatuses}
          />
        </Flex.Item>
      </Flex>
      {isStatusLate && (
        <TimeLateInput
          lateSubmissionInterval={props.lateSubmissionInterval}
          timeLate={timeLate}
          setTimeLate={setTimeLate}
          updateTimeLate={updateTimeLate}
          subAssignmentTag={props.subAssignmentSubmission.sub_assignment_tag}
          data-testid={
            props.subAssignmentSubmission.sub_assignment_tag + '-checkpoint-time-late-input'
          }
        />
      )}
      {!props.subAssignmentSubmission.grade_matches_current_submission && (
        <Flex direction="column" margin="none none small">
          <Flex.Item>
            <UseSameGrade
              onUseSameGrade={() => {
                props.updateSubmissionGrade({
                  subAssignmentTag: props.subAssignmentSubmission.sub_assignment_tag,
                  courseId: props.assignment.course_id,
                  assignmentId: props.assignment.id,
                  studentId: props.subAssignmentSubmission.user_id,
                  grade: props.subAssignmentSubmission.entered_grade,
                })
              }}
            />
          </Flex.Item>
        </Flex>
      )}
    </>
  )
}

type StatusSelectorProps = {
  subAssignmentTag: 'reply_to_topic' | 'reply_to_entry' | null
  status: string
  updateStatus: (value: string) => void
  customGradeStatusesEnabled: boolean
  customGradeStatuses?: GradeStatusUnderscore[]
}

const StatusSelector = (props: StatusSelectorProps) => {
  const statusAltText =
    props.subAssignmentTag === REPLY_TO_TOPIC
      ? I18n.t('Status for the Reply to Topic Checkpoint.')
      : I18n.t('Status for the Required Replies Checkpoint.')

  return (
    <SimpleSelect
      renderLabel={
        <AccessibleContent alt={statusAltText}>
          <div style={{padding: '0.2rem 0 1.3rem'}}>
            <Text size="small" weight="bold">
              {I18n.t('Status')}
            </Text>
          </div>
        </AccessibleContent>
      }
      assistiveText={I18n.t('Use arrow keys to navigate status options.')}
      value={props.status}
      onChange={(_e, {value}) => {
        if (typeof value !== 'string') return

        props.updateStatus(value)
      }}
      data-testid={props.subAssignmentTag + '-checkpoint-status-select'}
    >
      <SimpleSelect.Option id={NONE} value={NONE}>
        {I18n.t('None')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id={LATE} value={LATE}>
        {I18n.t('Late')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id={MISSING} value={MISSING}>
        {I18n.t('Missing')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id={EXCUSED} value={EXCUSED}>
        {I18n.t('Excused')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id={EXTENDED} value={EXTENDED}>
        {I18n.t('Extended')}
      </SimpleSelect.Option>
      {props.customGradeStatusesEnabled &&
        props.customGradeStatuses?.map(status => (
          <SimpleSelect.Option key={status.id} id={status.id} value={status.id}>
            {status.name}
          </SimpleSelect.Option>
        ))}
    </SimpleSelect>
  )
}

type TimeLateInputProps = {
  subAssignmentTag: 'reply_to_topic' | 'reply_to_entry' | null
  lateSubmissionInterval: string
  timeLate: string
  setTimeLate: (value: string) => void // This one only changes state
  updateTimeLate: (value: string) => void // This one updates the backend
}

const TimeLateInput = (props: TimeLateInputProps) => {
  return (
    <Flex margin="none none small">
      <Flex.Item width="100%">
        <View margin="small none none">
          <TextInput
            renderLabel={
              <div style={{padding: '0.2rem 0 0'}}>
                <Text size="small" weight="bold">
                  {props.lateSubmissionInterval === 'day'
                    ? I18n.t('Days Late')
                    : I18n.t('Hours Late')}
                </Text>
              </div>
            }
            value={props.timeLate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
              props.setTimeLate(e.target.value)
            }}
            onBlur={() => {
              props.updateTimeLate(props.timeLate)
            }}
            width="45%"
            data-testid={props.subAssignmentTag + '-checkpoint-time-late-input'}
          />
        </View>
      </Flex.Item>
    </Flex>
  )
}
