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

import {Flex} from '@instructure/ui-flex'
import GradeInput from './GradeInput'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import React, {useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  type CheckpointState,
  EXCUSED,
  EXTENDED,
  LATE,
  MISSING,
  NONE,
  REPLY_TO_TOPIC,
} from './SubmissionTray'
// @ts-expect-error
import type {GradingStandard, PendingGradeInfo} from '../gradebook.d'
import {
  CamelizedAssignment,
  type GradeEntryMode,
  GradeResult,
  type SubmissionData,
} from '@canvas/grading/grading.d'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'

const I18n = createI18nScope('gradebook')

type Props = {
  hasCheckpoints: boolean
  checkpointStates: CheckpointState[]
  subAssignmentTag: string
  assignment: CamelizedAssignment
  gradingDisabled: boolean
  enterGradesAs: GradeEntryMode
  gradingScheme: GradingStandard[] | null
  pointsBasedGradingScheme: boolean
  pendingGradeInfo: PendingGradeInfo
  onGradeSubmission: (submission: SubmissionData, gradeInfo: GradeResult) => void
  scalingFactor: number
  submission: SubmissionData
  submissionUpdating: boolean
  header: string
  updateCheckpointStates: (subAssignmentTag: string, key: string, value: string) => void
  latePolicy: {
    lateSubmissionInterval: string
  }
  customGradeStatusesEnabled: boolean
  customGradeStatuses?: GradeStatus[]
}

export const InputsForCheckpoints = (props: Props) => {
  const standardStatuses: string[] = [NONE, LATE, MISSING, EXCUSED, EXTENDED]

  const checkpointState = props.checkpointStates.find(
    checkpoint => checkpoint.label === props.subAssignmentTag,
  )

  const [localTimeLate, setLocalTimeLate] = useState(checkpointState?.timeLate || '')
  const checkpointStatus = checkpointState?.customGradeStatusId || checkpointState?.status
  const isStatusLate = checkpointStatus === LATE

  useEffect(() => {
    // @ts-expect-error
    setLocalTimeLate(checkpointState?.timeLate)
    // @ts-expect-error
  }, [checkpointState.timeLate])

  const getSubAssignment = (
    hasCheckpoints: boolean,
    assignment: CamelizedAssignment,
    subAssignmentTag: string,
  ) => {
    if (!hasCheckpoints) {
      return assignment
    }

    const subAssignment = assignment.checkpoints
      ? assignment.checkpoints.find(sub => sub.tag === subAssignmentTag)
      : null

    if (!subAssignment) {
      return assignment
    }

    return {
      ...assignment,
      pointsPossible: subAssignment.points_possible,
    }
  }

  const statusAltText =
    props.subAssignmentTag === REPLY_TO_TOPIC
      ? I18n.t('Status for the Reply to Topic Checkpoint.')
      : I18n.t('Status for the Required Replies Checkpoint.')

  return props.hasCheckpoints ? (
    <>
      <Flex margin="none none small" gap="small" alignItems="start">
        <Flex.Item shouldShrink={true}>
          <GradeInput
            assignment={getSubAssignment(
              props.hasCheckpoints,
              props.assignment,
              props.subAssignmentTag,
            )}
            disabled={props.gradingDisabled}
            enterGradesAs={props.enterGradesAs}
            gradingScheme={props.gradingScheme}
            pointsBasedGradingScheme={props.pointsBasedGradingScheme}
            pendingGradeInfo={props.pendingGradeInfo}
            onSubmissionUpdate={props.onGradeSubmission}
            scalingFactor={props.scalingFactor}
            submission={props.submission}
            submissionUpdating={props.submissionUpdating}
            subAssignmentTag={props.subAssignmentTag}
            header={props.header}
            inputDisplay="block"
          />
        </Flex.Item>
        <Flex.Item shouldShrink={true}>
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
            value={checkpointStatus}
            onChange={(_e, {value}) => {
              props.updateCheckpointStates(props.subAssignmentTag, 'timeLate', '0')
              // @ts-expect-error
              if (standardStatuses.includes(value)) {
                props.updateCheckpointStates(
                  props.subAssignmentTag,
                  'status',
                  value?.toString() || NONE,
                )
              } else {
                // @ts-expect-error
                props.updateCheckpointStates(props.subAssignmentTag, 'customGradeStatusId', value)
              }
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
        </Flex.Item>
      </Flex>
      {isStatusLate && (
        <Flex margin="none none small">
          <Flex.Item width="100%">
            <View margin="small none none">
              <TextInput
                renderLabel={
                  <div style={{padding: '0.2rem 0 0'}}>
                    <Text size="small" weight="bold">
                      {props.latePolicy.lateSubmissionInterval === 'day'
                        ? I18n.t('Days Late')
                        : I18n.t('Hours Late')}
                    </Text>
                  </div>
                }
                value={localTimeLate}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                  setLocalTimeLate(e.target.value)
                }}
                onBlur={() => {
                  props.updateCheckpointStates(props.subAssignmentTag, 'timeLate', localTimeLate)
                }}
                width="45%"
                data-testid={props.subAssignmentTag + '-checkpoint-time-late-input'}
              />
            </View>
          </Flex.Item>
        </Flex>
      )}
    </>
  ) : null
}
