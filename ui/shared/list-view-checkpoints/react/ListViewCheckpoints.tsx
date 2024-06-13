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
import {IconArrowNestLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Assignment, Checkpoint} from '../../../api.d'

const I18n = useI18nScope('assignment')

const REPLY_TO_TOPIC: string = 'reply_to_topic'

export type AssignmentCheckpoints = Pick<Assignment, 'id' | 'checkpoints' | 'discussion_topic'>

export type StudentViewCheckpointProps = {
  assignment: AssignmentCheckpoints
}

export type CheckpointProps = {
  assignment: AssignmentCheckpoints
  checkpoint: Checkpoint
}

const createDateTimeFormatter = () => {
  return Intl.DateTimeFormat(ENV.LOCALE, {
    month: 'short',
    day: 'numeric',
    timeZone: ENV.TIMEZONE,
  })
}

const dateFormatter = createDateTimeFormatter()

export const ListViewCheckpoints = ({assignment}: StudentViewCheckpointProps) => {
  return (
    <>
      {assignment.checkpoints.map(checkpoint => (
        <CheckpointItem
          checkpoint={checkpoint}
          assignment={assignment}
          key={`${assignment.id}_${checkpoint.tag}`}
        />
      ))}
    </>
  )
}

const CheckpointItem = React.memo(({checkpoint, assignment}: CheckpointProps) => {
  const getCheckpointDueDate = () => {
    if (checkpoint.due_at) {
      return dateFormatter.format(new Date(checkpoint.due_at))
    }

    // Once VICE-4350 is completed, modify this to find the due date from the checkpoint overrides
    for (const override of checkpoint.overrides) {
      if (
        override.student_ids &&
        ENV.current_user_id &&
        override.student_ids.includes(ENV.current_user_id)
      ) {
        return dateFormatter.format(new Date(override.due_at))
      }
    }

    return I18n.t('No Due Date')
  }

  const renderCheckpointTitle = () => {
    if (checkpoint.tag === REPLY_TO_TOPIC) {
      return I18n.t('Reply To Topic')
    } else {
      // if it's not reply to topic, it must be reply to entry
      const translatedReplyToEntryRequiredCount = I18n.n(
        assignment.discussion_topic.reply_to_entry_required_count
      )
      return I18n.t('Required Replies (%{requiredReplies})', {
        requiredReplies: translatedReplyToEntryRequiredCount,
      })
    }
  }

  return (
    <li className="context_module_item student-view cannot-duplicate indent_1">
      <div className="ig-row">
        <div className="ig-row__layout">
          <span className="type_icon display_icons" style={{fontSize: '1.125rem'}}>
            <View as="span" margin="0 0 0 medium">
              <IconArrowNestLine />
            </View>
          </span>
          <div className="ig-info">
            <span
              style={{color: 'var(--ic-brand-font-color-dark)'}}
              className="item_name ig-title title"
              data-testid={`${assignment.id}_${checkpoint.tag}_title`}
            >
              {renderCheckpointTitle()}
            </span>

            <div className="ig-details">
              <div
                className="ig-details__item"
                data-testid={`${assignment.id}_${checkpoint.tag}_due_date`}
              >
                {getCheckpointDueDate()}
              </div>
            </div>
          </div>
        </div>
      </div>
    </li>
  )
})
