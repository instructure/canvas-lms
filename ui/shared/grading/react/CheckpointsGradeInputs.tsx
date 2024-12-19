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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import DefaultGradeInput from '@canvas/grading/react/DefaultGradeInput'
import type {GradingType} from '../../../api'
import {useScope as createI18nScope} from '@canvas/i18n'

// The following are lean types to be used in this file only, to be TypeScript compliant
export type AssignmentCheckpoint = {
  tag: string
  points_possible: number
}

export type Assignment = {
  grading_type: GradingType
  checkpoints: AssignmentCheckpoint[]
}

type Props = {
  assignment: Assignment
}

export const REPLY_TO_TOPIC = 'reply_to_topic'
export const REPLY_TO_ENTRY = 'reply_to_entry'

const I18n = createI18nScope('sharedSetDefaultGradeDialog')

export default function CheckpointsGradeInputs({assignment}: Props) {
  return (
    <Flex>
      <Flex.Item shouldShrink={true}>
        <View as="div" margin="small medium">
          <DefaultGradeInput
            disabled={false}
            gradingType={assignment.grading_type}
            onGradeInputChange={() => {}}
            header={I18n.t('Reply to Topic')}
            outOfTextValue={
              assignment.checkpoints &&
              assignment.checkpoints
                .find(cp => cp.tag === REPLY_TO_TOPIC)
                ?.points_possible.toString()
            }
            name="reply_to_topic_input"
          />
        </View>
      </Flex.Item>
      <Flex.Item shouldShrink={true}>
        <View as="div" margin="small medium">
          <DefaultGradeInput
            disabled={false}
            gradingType={assignment.grading_type}
            onGradeInputChange={() => {}}
            header={I18n.t('Required Replies')}
            outOfTextValue={
              assignment.checkpoints &&
              assignment.checkpoints
                .find(cp => cp.tag === REPLY_TO_ENTRY)
                ?.points_possible.toString()
            }
            name="reply_to_entry_input"
          />
        </View>
      </Flex.Item>
    </Flex>
  )
}
