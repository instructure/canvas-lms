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
  const hasDueOrLockDate =
    content?.dueAt ||
    content?.lockAt ||
    content?.assignmentOverrides?.edges?.some(({node}) => node.dueAt)

  let dueDatesCount =
    content?.assignmentOverrides?.edges?.filter(({node}) => !!node.dueAt).length || 0
  if (content?.dueAt) {
    dueDatesCount += 1
  }

  const tooltipContents = useMemo(() => {
    const dueAtCounts =
      content?.assignmentOverrides?.edges?.reduce((acc, edge) => {
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

    const contents = Object.keys(dueAtCounts).map(dueAt => {
      return (
        <Flex justifyItems="center" key={`due_at_${contentTagId}_${dueAt}`}>
          <Flex.Item margin="0 small">
            <Text weight="bold">{aoSetDescriber(dueAtCounts[dueAt])}</Text>
          </Flex.Item>
          <Flex.Item>
            <FriendlyDatetime
              data-testid="due-date"
              format={I18n.t('#date.formats.medium')}
              dateTime={dueAt}
            />
          </Flex.Item>
        </Flex>
      )
    })

    if (content?.dueAt) {
      contents.push(
        <Flex justifyItems="center" key={`due_at_${contentTagId}_default`}>
          <Flex.Item margin="0 small">
            <Text weight="bold">{I18n.t('Everyone else')}</Text>
          </Flex.Item>
          <Flex.Item>
            <FriendlyDatetime
              data-testid="due-date"
              format={I18n.t('#date.formats.medium')}
              dateTime={content.dueAt}
            />
          </Flex.Item>
        </Flex>,
      )
    }

    return <span data-testid="override-details">{contents}</span>
  }, [content])

  if (!content || !hasDueOrLockDate) return null

  if (dueDatesCount == 1) {
    return (
      <Flex.Item>
        <Text weight="normal" size="x-small">
          <FriendlyDatetime
            data-testid="due-date"
            format={I18n.t('#date.formats.medium')}
            dateTime={
              content.dueAt ||
              content.lockAt ||
              content.assignmentOverrides?.edges?.find(({node}) => node.dueAt)?.node?.dueAt ||
              null
            }
          />
        </Text>
      </Flex.Item>
    )
  } else {
    return (
      <Flex.Item>
        <Link href={`/courses/${ENV.course_id}/modules/items/${contentTagId}`} isWithinText={false}>
          <Tooltip renderTip={tooltipContents}>
            <Text weight="normal" size="x-small">
              {I18n.t('Multiple Due Dates')}
            </Text>
          </Tooltip>
        </Link>
      </Flex.Item>
    )
  }
}

export default DueDateLabel
