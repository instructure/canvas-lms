/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {datetimeString, dateString} from '@canvas/datetime/date-functions'

const I18n = createI18nScope('assignments')

export type AvailabilityStatus = 'open' | 'pending' | 'closed'

interface AvailabilityStatusInfo {
  status: AvailabilityStatus | null
  date: string | null
}

interface DateInfo {
  dueFor: string
  dueAt: string | null
  unlockAt?: string | null
  lockAt?: string | null
  availabilityStatus?: AvailabilityStatusInfo
}

interface DefaultDates {
  dueFor?: string
  dueAt: string | null
  unlockAt: string | null
  lockAt: string | null
  available?: boolean
  pending?: boolean
  open?: boolean
  closed?: boolean
  setType?: string
  availabilityStatus?: AvailabilityStatusInfo
}

interface PeerReviewSubAssignmentAttributes {
  id: string
  points_possible: number | null
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
  all_dates?: DateInfo[]
  availability_status?: AvailabilityStatusInfo
  defaultDates?: DefaultDates
  singleSectionAvailability?: AvailabilityStatusInfo
}

interface AssignmentAttributes {
  id: string
  name: string
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
  points_possible: number | null
  all_dates?: DateInfo[]
  peer_reviews?: boolean
  peer_review_count?: number
  peer_review_sub_assignment?: PeerReviewSubAssignmentAttributes | null
  html_url?: string
  availability_status?: AvailabilityStatusInfo
  defaultDates?: DefaultDates
  singleSectionAvailability?: AvailabilityStatusInfo
}

export interface PeerReviewInfoProps {
  assignment: AssignmentAttributes
}

const hasMultipleDates = (allDates?: DateInfo[]): boolean => {
  if (!allDates) return false
  return allDates.length > 1
}

interface AvailabilityDateViewProps {
  date: DateInfo
}

const AvailabilityDateView: React.FC<AvailabilityDateViewProps> = ({
  date,
}: AvailabilityDateViewProps) => {
  const availability = date.availabilityStatus

  if (!availability || !availability.status) {
    return <View>{I18n.t('Available')}</View>
  }

  switch (availability.status) {
    case 'open':
      return availability.date ? (
        <View>
          {I18n.t('Available until %{date}', {
            date: datetimeString(availability.date, {timezone: ENV.TIMEZONE, format: 'short'}),
          })}
        </View>
      ) : (
        <View>{I18n.t('Available')}</View>
      )
    case 'pending':
      return availability.date ? (
        <View>
          {I18n.t('Not available until %{date}', {
            date: datetimeString(availability.date, {timezone: ENV.TIMEZONE, format: 'short'}),
          })}
        </View>
      ) : (
        <View>{I18n.t('Not available')}</View>
      )
    case 'closed':
      return <View>{I18n.t('Closed')}</View>
    default:
      return <View>{I18n.t('Available')}</View>
  }
}

interface DueDateViewProps {
  date: DateInfo
}

const DueDateView: React.FC<DueDateViewProps> = ({date}: DueDateViewProps) => {
  const dueDate = dateString(date.dueAt, {timezone: ENV.TIMEZONE})

  return <>{date.dueAt ? <View>{dueDate}</View> : <View>{'-'}</View>}</>
}

interface TooltipContentProps {
  dates: DateInfo[]
  type: 'availability' | 'due'
}

const TooltipContent: React.FC<TooltipContentProps> = ({dates, type}: TooltipContentProps) => (
  <View as="div" padding="xxx-small" display="block">
    {dates.map((date: DateInfo, index: number) => (
      <Flex
        key={`${date.dueFor}-${index}`}
        gap="x-small"
        alignItems="start"
        margin={index < dates.length - 1 ? 'none none xx-small none' : 'none'}
      >
        <Flex.Item shouldGrow={false} shouldShrink={false} size="7.35rem">
          <View as="div" className="tooltip-label">
            {date.dueFor}
          </View>
        </Flex.Item>
        <Flex.Item shouldGrow={false} shouldShrink={true} size="7.35rem">
          <View as="div" className="tooltip-value">
            {type === 'availability' ? (
              <AvailabilityDateView date={date} />
            ) : (
              <DueDateView date={date} />
            )}
          </View>
        </Flex.Item>
      </Flex>
    ))}
  </View>
)

interface MultipleDatesLinkProps {
  tooltipContent: React.ReactNode
  linkHref?: string
}

const MultipleDatesLink: React.FC<MultipleDatesLinkProps> = ({
  tooltipContent,
  linkHref,
}: MultipleDatesLinkProps) => (
  <Tooltip renderTip={tooltipContent} on={['hover', 'focus']}>
    <Link href={linkHref || '#'} isWithinText={false}>
      {I18n.t('Multiple Dates')}
    </Link>
  </Tooltip>
)

interface DateSectionData {
  unlock_at: string | null
  lock_at: string | null
  due_at: string | null
  points_possible: number | null
  all_dates?: DateInfo[]
  availability_status?: AvailabilityStatusInfo
  defaultDates?: DefaultDates
  singleSectionAvailability?: AvailabilityStatusInfo
}

interface DateSectionProps {
  label: React.ReactNode
  className?: string
  data: DateSectionData
  multipleDates: boolean
  htmlUrl: string
}

const DateSection: React.FC<DateSectionProps> = ({
  label,
  className = '',
  data,
  multipleDates,
  htmlUrl,
}: DateSectionProps) => {
  const defaultDates = data.defaultDates || {
    dueAt: data.due_at,
    unlockAt: data.unlock_at,
    lockAt: data.lock_at,
  }

  let availability = data.singleSectionAvailability ||
    data.availability_status || {status: null, date: null}
  let singleDueDate = null

  if (!multipleDates && data.all_dates && data.all_dates.length > 0) {
    for (const dateEntry of data.all_dates) {
      if (dateEntry.dueAt || dateEntry.unlockAt || dateEntry.lockAt) {
        if (dateEntry.dueAt) {
          singleDueDate = dateEntry.dueAt
        }
        if (dateEntry.availabilityStatus) {
          availability = dateEntry.availabilityStatus
        }
        break
      }
    }
  }

  if (singleDueDate === null) {
    singleDueDate = defaultDates.dueAt
  }

  const showAvailability = multipleDates || availability.status !== null
  const showDueDate = multipleDates || singleDueDate !== null
  const showPoints = data.points_possible != null && data.points_possible > 0

  if (!showAvailability && !showDueDate && !showPoints) {
    return null
  }

  return (
    <View className={`info-section${className ? ` ${className}` : ''}`}>
      <View className="date-section-label">
        <Text size="x-small" weight="bold">
          {label}
        </Text>
      </View>{' '}
      {multipleDates ? (
        <>
          {showAvailability && (
            <View className="info-item">
              <Text size="x-small" weight="bold">
                {I18n.t('Available')}
              </Text>{' '}
              <MultipleDatesLink
                tooltipContent={<TooltipContent dates={data.all_dates || []} type="availability" />}
                linkHref={htmlUrl}
              />
            </View>
          )}
          {showDueDate && (
            <View className="info-item">
              <Text size="x-small" weight="bold">
                {I18n.t('Due')}
              </Text>{' '}
              <MultipleDatesLink
                tooltipContent={<TooltipContent dates={data.all_dates || []} type="due" />}
                linkHref={htmlUrl}
              />
            </View>
          )}
        </>
      ) : (
        <>
          {availability.status === 'open' && availability.date && (
            <View className="info-item">
              <Text size="x-small" weight="bold">
                {I18n.t('Available until')}
              </Text>{' '}
              <Text size="x-small">
                {datetimeString(availability.date, {timezone: ENV.TIMEZONE})}
              </Text>
            </View>
          )}
          {availability.status === 'pending' && availability.date && (
            <View className="info-item">
              <Text size="x-small" weight="bold">
                {I18n.t('Not available until')}
              </Text>{' '}
              <Text size="x-small">
                {datetimeString(availability.date, {timezone: ENV.TIMEZONE})}
              </Text>
            </View>
          )}
          {availability.status === 'closed' && (
            <View className="info-item">
              <Text size="x-small" weight="bold">
                {I18n.t('Closed')}
              </Text>
            </View>
          )}
          {singleDueDate && (
            <View className="info-item">
              <Text size="x-small" weight="bold">
                {I18n.t('Due')}
              </Text>{' '}
              <Text size="x-small">{datetimeString(singleDueDate, {timezone: ENV.TIMEZONE})}</Text>
            </View>
          )}
        </>
      )}
      {showPoints && (
        <View className="info-item">
          <Text size="x-small">
            {I18n.t({one: '1 pt', other: '%{count} pts'}, {count: data.points_possible})}
          </Text>
        </View>
      )}
    </View>
  )
}

interface AssignmentSectionProps {
  assignment: AssignmentAttributes
  multipleDates: boolean
}

const AssignmentSection: React.FC<AssignmentSectionProps> = ({
  assignment,
  multipleDates,
}: AssignmentSectionProps) => (
  <DateSection
    label={I18n.t('Assignment:')}
    data={assignment}
    multipleDates={multipleDates}
    htmlUrl={assignment.html_url || '#'}
  />
)

interface PeerReviewSectionProps {
  peerReviewSub: PeerReviewSubAssignmentAttributes
  peerReviewCount: number
  htmlUrl: string
}

const PeerReviewSection: React.FC<PeerReviewSectionProps> = ({
  peerReviewSub,
  peerReviewCount,
  htmlUrl,
}: PeerReviewSectionProps) => {
  const multipleDates = hasMultipleDates(peerReviewSub.all_dates)
  return (
    <DateSection
      label={I18n.t(
        {one: 'Peer Review (%{count}):', other: 'Peer Reviews (%{count}):'},
        {count: peerReviewCount},
      )}
      className="peer-review-info"
      data={peerReviewSub}
      multipleDates={multipleDates}
      htmlUrl={htmlUrl}
    />
  )
}

export const PeerReviewInfo: React.FC<PeerReviewInfoProps> = ({
  assignment,
}: PeerReviewInfoProps) => {
  const peerReviewSub = assignment.peer_review_sub_assignment

  if (!peerReviewSub) {
    return null
  }

  const peerReviewCount = assignment.peer_review_count || 0
  const multipleDates = hasMultipleDates(assignment.all_dates)
  const htmlUrl = assignment.html_url || '#'

  return (
    <>
      <AssignmentSection assignment={assignment} multipleDates={multipleDates} />
      <PeerReviewSection
        peerReviewSub={peerReviewSub}
        peerReviewCount={peerReviewCount}
        htmlUrl={htmlUrl}
      />
    </>
  )
}

export default PeerReviewInfo
