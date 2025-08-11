/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {ModuleItemContent, DueAtCounts, DueAtCount} from '../utils/types'
import {Tooltip} from '@instructure/ui-tooltip'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('context_modules_v2')

export interface DueDateLabelProps {
  contentTagId: string
  content: ModuleItemContent
}

const aoSetDescriber = (dueAtCount: DueAtCount) => {
  const description: string[] = []

  if (dueAtCount.groups) {
    description.push(
      I18n.t(
        {
          one: '1 group',
          other: '%{count} groups',
        },
        {count: dueAtCount.groups},
      ),
    )
  }

  if (dueAtCount.students) {
    description.push(
      I18n.t(
        {
          one: '1 student',
          other: '%{count} students',
        },
        {count: dueAtCount.students},
      ),
    )
  }

  if (dueAtCount.sections) {
    description.push(
      I18n.t(
        {
          one: '1 section',
          other: '%{count} sections',
        },
        {count: dueAtCount.sections},
      ),
    )
  }

  return description.join(', ')
}

const DueDateLabel: React.FC<DueDateLabelProps> = ({contentTagId, content}) => {
  const isStandardizedFormattingEnabled = !!ENV.FEATURES?.standardize_assignment_date_formatting

  const getAssignmentOverrides = (content: ModuleItemContent) => {
    return content?.assignmentOverrides || content?.assignment?.assignmentOverrides
  }

  const getBaseDueDate = (content: ModuleItemContent) => {
    // For discussions, the base due date might be on the assignment
    if (content?.type === 'Discussion' && content?.assignment?.dueAt) {
      return content.assignment.dueAt
    }
    // For other content types, use the direct dueAt
    return content?.dueAt
  }

  const assignmentOverrides = getAssignmentOverrides(content)
  const baseDueDate = getBaseDueDate(content)
  const assignedToDates = isStandardizedFormattingEnabled ? content?.assignedToDates : null
  const useStandardizedDates = assignedToDates && assignedToDates.length > 0
  const isUngradedDiscussion = content?.type === 'Discussion' && content?.graded === false

  const tooltipContents = useMemo(() => {
    if (useStandardizedDates) {
      return (
        <span data-testid="override-details">
          {assignedToDates.map((dateHash, index) => (
            <Flex justifyItems="center" key={`${contentTagId}_${index}`}>
              <Flex.Item margin="0 small">
                <Text weight="bold">{dateHash.title || 'Unknown'}</Text>
              </Flex.Item>
              <Flex.Item>
                <FriendlyDatetime
                  data-testid="due-date"
                  format={I18n.t('#date.formats.date_at_time')}
                  dateTime={dateHash.dueAt || null}
                  alwaysUseSpecifiedFormat={true}
                />
              </Flex.Item>
            </Flex>
          ))}
        </span>
      )
    }

    // Fallback to existing client-side logic
    const contents: React.ReactNode[] = []
    const dueAtCounts =
      assignmentOverrides?.edges?.reduce((acc, edge) => {
        const {node} = edge

        if (node.dueAt) {
          acc[node.dueAt] ||= {}
          if (node.set.groupId) {
            acc[node.dueAt].groups ||= 0
            acc[node.dueAt].groups! += 1
          }
          if (node.set.sectionId) {
            acc[node.dueAt].sections ||= 0
            acc[node.dueAt].sections! += 1
          }
          if (node.set.students) {
            acc[node.dueAt].students ||= 0
            acc[node.dueAt].students! += node.set.students.length
          }
        }

        return acc
      }, {} as DueAtCounts) || {}

    const overrideContents = Object.keys(dueAtCounts).map(dueAt => {
      return (
        <Flex justifyItems="center" key={`due_at_${contentTagId}_${dueAt}`}>
          <Flex.Item margin="0 small">
            <Text weight="bold">{aoSetDescriber(dueAtCounts[dueAt])}</Text>
          </Flex.Item>
          <Flex.Item>
            <Text size="x-small">
              <FriendlyDatetime
                data-testid="due-date"
                format={I18n.t('#date.formats.date_at_time')}
                dateTime={dueAt}
                alwaysUseSpecifiedFormat={true}
              />
            </Text>
          </Flex.Item>
        </Flex>
      )
    })

    contents.push(...overrideContents)

    if (baseDueDate) {
      contents.push(
        <Flex justifyItems="center" key={`due_at_${contentTagId}_default`}>
          <Flex.Item margin="0 small">
            <Text weight="bold">{I18n.t('Everyone else')}</Text>
          </Flex.Item>
          <Flex.Item>
            <Text size="x-small">
              <FriendlyDatetime
                data-testid="due-date"
                format={I18n.t('#date.formats.date_at_time')}
                dateTime={baseDueDate}
                alwaysUseSpecifiedFormat={true}
              />
            </Text>
          </Flex.Item>
        </Flex>,
      )
    }

    return <span data-testid="override-details">{contents}</span>
  }, [useStandardizedDates, assignedToDates, assignmentOverrides?.edges, baseDueDate, contentTagId])

  // Handle standardized dates first
  if (useStandardizedDates) {
    if (assignedToDates.length === 1) {
      const singleDate = assignedToDates[0]
      return (
        <Text size="x-small">
          <FriendlyDatetime
            data-testid="due-date"
            format={I18n.t('#date.formats.medium')}
            dateTime={singleDate.dueAt || null}
            alwaysUseSpecifiedFormat={true}
          />
        </Text>
      )
    } else {
      return (
        <Link href={`/courses/${ENV.course_id}/modules/items/${contentTagId}`} isWithinText={false}>
          <Tooltip renderTip={tooltipContents}>
            <Text weight="normal" size="x-small">
              {I18n.t('Multiple Due Dates')}
            </Text>
          </Tooltip>
        </Link>
      )
    }
  }

  // Handle legacy date logic
  const hasDueDate = baseDueDate || assignmentOverrides?.edges?.some(({node}) => node.dueAt)

  if (!hasDueDate) {
    return null
  }

  // Collect all unique due dates
  const allDueDates = new Set<string>()
  const hasOverrides = assignmentOverrides?.edges?.length && assignmentOverrides?.edges?.length > 0

  // Add override dates
  assignmentOverrides?.edges?.forEach(({node}) => {
    if (node.dueAt) {
      allDueDates.add(node.dueAt)
    }
  })

  // Add base due date if it exists and isn't already in overrides
  if (baseDueDate) {
    allDueDates.add(baseDueDate)
  }

  // Count total effective due dates (base due date + overrides with different dates)
  const overridesWithDates = assignmentOverrides?.edges?.filter(({node}) => node.dueAt).length || 0
  let totalDatesCount = overridesWithDates

  // Add base due date if it exists and is different from override dates
  if (baseDueDate && !assignmentOverrides?.edges?.some(({node}) => node.dueAt === baseDueDate)) {
    totalDatesCount += 1
  }

  // Show "Multiple Due Dates" if there are multiple unique dates (Canvas requirement)
  const hasMultipleDates = allDueDates.size > 1

  if (allDueDates.size === 0) {
    if (hasOverrides) {
      // Has overrides but no dates - show "No Due Date"
      return <Text size="x-small">{I18n.t('No Due Date')}</Text>
    } else {
      // No overrides and no dates - return null
      return null
    }
  } else if (hasMultipleDates) {
    // Multiple dates (base + overrides) - show "Multiple Due Dates"
    return (
      <Link href={`/courses/${ENV.course_id}/modules/items/${contentTagId}`} isWithinText={false}>
        <Tooltip renderTip={tooltipContents}>
          <Text weight="normal" size="x-small">
            {I18n.t('Multiple Due Dates')}
          </Text>
        </Tooltip>
      </Link>
    )
  } else {
    // Single override or single date - get the actual date from the Set
    const singleDate = Array.from(allDueDates)[0]
    return (
      <Text size="x-small">
        <FriendlyDatetime
          data-testid="due-date"
          format={I18n.t('#date.formats.medium')}
          alwaysUseSpecifiedFormat={true}
          dateTime={singleDate || null}
        />
      </Text>
    )
  }
}

export default DueDateLabel
