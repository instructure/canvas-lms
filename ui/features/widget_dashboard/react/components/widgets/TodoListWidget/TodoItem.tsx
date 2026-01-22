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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {IconCheckPlusLine, IconCheckLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import type {PlannerItem} from './types'
import {formatDate, getPlannableTypeLabel, isOverdue} from './utils'
import {usePlannerOverride} from './hooks/usePlannerOverride'

const I18n = createI18nScope('widget_dashboard')

interface TodoItemProps {
  item: PlannerItem
}

const TodoItem: React.FC<TodoItemProps> = ({item}) => {
  const dateText = formatDate(item.plannable_date)
  const isItemOverdue = isOverdue(item.plannable_date)
  const typeLabel = getPlannableTypeLabel(item.plannable_type)
  const {toggleComplete, isLoading} = usePlannerOverride()

  const isMarkedComplete = item.planner_override?.marked_complete ?? false

  // For planner notes, course_id may be in plannable.course_id instead of item.course_id
  const courseId = item.course_id || item.plannable.course_id

  const handleCheckboxClick = () => {
    toggleComplete({
      item,
      markedComplete: !isMarkedComplete,
    })
  }

  return (
    <View
      as="div"
      padding="small"
      margin="small 0"
      borderWidth="small"
      borderRadius="large"
      background="secondary"
      data-testid={`todo-item-${item.plannable_id}`}
      themeOverride={{
        backgroundSecondary: '#F9FAFA',
      }}
    >
      <Flex gap="small" alignItems="center">
        <Flex.Item shouldGrow shouldShrink>
          <Flex direction="column" gap="x-small">
            <Flex.Item>
              <Text size="small" color="secondary">
                {typeLabel}
              </Text>
            </Flex.Item>

            <Flex.Item>
              <Link
                href={item.html_url}
                isWithinText={false}
                data-testid={`todo-link-${item.plannable_id}`}
              >
                <Text weight="bold" color={isMarkedComplete ? 'secondary' : undefined}>
                  {item.plannable.title}
                </Text>
              </Link>
            </Flex.Item>

            {item.plannable.details && (
              <Flex.Item>
                <Text size="small" color="secondary" lineHeight="condensed">
                  {item.plannable.details}
                </Text>
              </Flex.Item>
            )}

            {courseId && item.context_name && (
              <Flex.Item>
                <Link
                  href={`/courses/${courseId}`}
                  isWithinText={false}
                  data-testid={`todo-item-course-link-${item.plannable_id}`}
                >
                  <Text size="small" color="secondary">
                    {item.context_name}
                  </Text>
                </Link>
              </Flex.Item>
            )}

            <Flex.Item>
              <Text size="small">
                {dateText && (
                  <Text size="small" color={isItemOverdue ? 'danger' : 'secondary'}>
                    {dateText}
                  </Text>
                )}
                {dateText &&
                  item.plannable.points_possible !== undefined &&
                  item.plannable.points_possible !== null && (
                    <Text size="small" color="secondary">
                      {' | '}
                    </Text>
                  )}
                {item.plannable.points_possible !== undefined &&
                  item.plannable.points_possible !== null && (
                    <Text size="small" color="secondary">
                      {item.plannable.points_possible} pts
                    </Text>
                  )}
              </Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item>
          {isLoading ? (
            <Spinner
              renderTitle={I18n.t('Updating...')}
              size="x-small"
              data-testid={`todo-checkbox-loading-${item.plannable_id}`}
            />
          ) : (
            <IconButton
              screenReaderLabel={
                isMarkedComplete
                  ? I18n.t('Mark %{title} as incomplete', {title: item.plannable.title})
                  : I18n.t('Mark %{title} as complete', {title: item.plannable.title})
              }
              onClick={handleCheckboxClick}
              data-testid={`todo-checkbox-${item.plannable_id}`}
            >
              {isMarkedComplete ? <IconCheckLine color="success" /> : <IconCheckPlusLine />}
            </IconButton>
          )}
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default TodoItem
