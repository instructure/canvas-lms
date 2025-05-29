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
import {useScope as createI18nScope} from '@canvas/i18n'
import type {Assignment, Checkpoint} from '../../../api'
import {Tooltip} from '@instructure/ui-tooltip'
import {datetimeString} from '@canvas/datetime/date-functions'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('assignment')

const REPLY_TO_TOPIC = 'reply_to_topic'

type AssignmentCheckpoints = Pick<
  Assignment,
  'id' | 'checkpoints' | 'discussion_topic' | 'points_possible'
>

type TeacherCheckpointsInfoProps = {
  assignment: AssignmentCheckpoints
}

interface DueDate {
  dueFor: string
  dueAt: string | null
}

const getCheckpointDueDates = (
  checkpoint?: Pick<Checkpoint, 'overrides' | 'due_at'>,
): {multipleDueDates: boolean; dates: DueDate[]} => {
  if (!checkpoint)
    return {multipleDueDates: false, dates: [{dueFor: I18n.t('Everyone'), dueAt: null}]}

  if (checkpoint.overrides && checkpoint.overrides.length > 0) {
    const dates = checkpoint.overrides.map(override => ({
      dueFor: override.title || I18n.t('Section'),
      dueAt: override.due_at,
    }))
    if (checkpoint.due_at) {
      dates.push({dueFor: I18n.t('Everyone else'), dueAt: checkpoint.due_at})
    }
    return {multipleDueDates: true, dates}
  }

  if (checkpoint.due_at) {
    return {
      multipleDueDates: false,
      dates: [{dueFor: I18n.t('Everyone'), dueAt: checkpoint.due_at}],
    }
  }

  return {multipleDueDates: false, dates: [{dueFor: I18n.t('Everyone'), dueAt: null}]}
}

const getAvailabilityInfo = (
  checkpoint?: Pick<Checkpoint, 'overrides' | 'unlock_at' | 'lock_at'> | undefined,
): {title: string; multipleDueDates: boolean; dates: DueDate[]} => {
  let title = ''
  let availability = null
  const dates = []
  if (!checkpoint)
    return {title, multipleDueDates: false, dates: [{dueFor: I18n.t('Everyone'), dueAt: null}]}

  if (checkpoint.overrides && checkpoint.overrides.length > 0) {
    title = I18n.t('Availability')
    checkpoint.overrides.forEach(override => {
      availability = getAvailabilityText(override.unlock_at, override.lock_at)
      if (availability.dueFor) {
        dates.push({
          dueFor: `${override.title} ${availability.dueFor}` || I18n.t('Section'),
          dueAt: availability.dueAt,
        })
      }
    })
    availability = getAvailabilityText(checkpoint.unlock_at, checkpoint.lock_at)
    if (availability.dueFor) {
      dates.push({
        dueFor: `${I18n.t('Everyone else')} ${availability.dueFor}`,
        dueAt: availability.dueAt,
      })
    }
    return {title, multipleDueDates: true, dates}
  }

  availability = getAvailabilityText(checkpoint.unlock_at, checkpoint.lock_at)
  return {
    title: availability.dueFor,
    multipleDueDates: false,
    dates: [{dueFor: I18n.t('Everyone'), dueAt: availability.dueAt}],
  }
}

const getAvailabilityText = (unlockAt: string | null, lockAt: string | null): DueDate => {
  const now = new Date()
  const isLocked = unlockAt && new Date(unlockAt) > now
  const isOpen = unlockAt && now > new Date(unlockAt)
  if (!unlockAt && !lockAt) return {dueFor: '', dueAt: null}
  if (!unlockAt && lockAt) return {dueFor: I18n.t('Available Until'), dueAt: lockAt}
  if (isOpen && !lockAt) return {dueFor: '', dueAt: null}
  if (isLocked) return {dueFor: I18n.t('Not Available Until'), dueAt: unlockAt}
  else return {dueFor: I18n.t('Available Until'), dueAt: lockAt}
}

const renderRequiredRepliesTitle = (assignment: AssignmentCheckpoints): string => {
  const translatedReplyToEntryRequiredCount = I18n.n(
    assignment.discussion_topic?.reply_to_entry_required_count ?? 0,
  )
  return I18n.t('Required Replies (%{requiredReplies})', {
    requiredReplies: translatedReplyToEntryRequiredCount,
  })
}

const TooltipContent: React.FC<{dates: DueDate[]}> = ({dates}) => (
  <dl className="vdd_tooltip_content dl-horizontal" style={{margin: 'small'}}>
    {dates.map(date => (
      <div key={`${date.dueFor}-${date.dueAt || 'no-date'}`} className="clearfix">
        <dt>{date.dueFor}</dt>
        <dd>
          {date.dueAt ? (
            <span title={new Date(date.dueAt).toLocaleString()}>
              {datetimeString(date.dueAt, {timezone: ENV.TIMEZONE})}
            </span>
          ) : (
            '-'
          )}
        </dd>
      </div>
    ))}
  </dl>
)
const CheckpointInfo: React.FC<{
  title: string
  dueDate: {multipleDueDates: boolean; dates: DueDate[]}
  testId: string
}> = ({title, dueDate, testId}) => (
  <span data-testid={testId}>
    <strong>{title}:</strong>{' '}
    {dueDate.multipleDueDates ? (
      <Tooltip renderTip={<TooltipContent dates={dueDate.dates} />} on={['hover', 'focus']}>
        <button
          type="button"
          onClick={e => e.preventDefault()}
          className="Button Button--link"
          style={{
            padding: 0,
            fontSize: 'inherit',
            marginTop: '-0.2em',
          }}
        >
          {I18n.t('Multiple Dates')}
        </button>
      </Tooltip>
    ) : dueDate.dates[0].dueAt ? (
      datetimeString(dueDate.dates[0].dueAt, {timezone: ENV.TIMEZONE})
    ) : (
      I18n.t('No Due Date')
    )}
  </span>
)

export const TeacherCheckpointsInfo: React.FC<TeacherCheckpointsInfoProps> = ({assignment}) => {
  const replyToTopicCheckpoint = assignment.checkpoints.find(cp => cp.tag === REPLY_TO_TOPIC)
  const requiredRepliesCheckpoint = assignment.checkpoints.find(cp => cp.tag !== REPLY_TO_TOPIC)
  const {title, ...availabilityDates} = getAvailabilityInfo(replyToTopicCheckpoint)
  return (
    <div
      style={{
        margin: '0',
        display: 'flex',
        gap: '.5rem',
      }}
    >
      {!!title && (
        <CheckpointInfo
          title={title}
          dueDate={availabilityDates}
          testId={`${assignment.id}_cp_availability`}
        />
      )}
      <CheckpointInfo
        title={I18n.t('Reply to Topic')}
        dueDate={getCheckpointDueDates(replyToTopicCheckpoint)}
        testId={`${assignment.id}_${REPLY_TO_TOPIC}`}
      />
      <CheckpointInfo
        title={renderRequiredRepliesTitle(assignment)}
        dueDate={getCheckpointDueDates(requiredRepliesCheckpoint)}
        testId={`${assignment.id}_required_replies`}
      />
      <Text size="x-small" data-testid={`${assignment.id}_points_possible`}>
        {I18n.t('%{points_possible} pts', {
          points_possible: assignment.points_possible,
        })}
      </Text>
    </div>
  )
}

export default TeacherCheckpointsInfo
