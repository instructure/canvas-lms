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
import {IconCheckPlusLine} from '@instructure/ui-icons'
import CourseCode from '../../shared/CourseCode'
import type {PlannerItem} from './types'
import {formatDate, getPlannableTypeLabel, isOverdue} from './utils'

const I18n = createI18nScope('widget_dashboard')

interface TodoItemProps {
  item: PlannerItem
}

const TodoItem: React.FC<TodoItemProps> = ({item}) => {
  const dateText = formatDate(item.plannable_date)
  const isItemOverdue = isOverdue(item.plannable_date)
  const typeLabel = getPlannableTypeLabel(item.plannable_type)

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
                <Text weight="bold">{item.plannable.title}</Text>
              </Link>
            </Flex.Item>

            {item.plannable.details && (
              <Flex.Item>
                <Text size="small" color="secondary" lineHeight="condensed">
                  {item.plannable.details}
                </Text>
              </Flex.Item>
            )}

            {item.course_id && (
              <Flex.Item>
                <Flex gap="x-small" alignItems="center" wrap="wrap">
                  <Flex.Item>
                    <CourseCode courseId={item.course_id} size="small" useCustomColors={true} />
                  </Flex.Item>
                  <Flex.Item>
                    <Text size="small" color="secondary">
                      |
                    </Text>
                  </Flex.Item>
                  <Flex.Item>
                    <Link
                      href={`/courses/${item.course_id}`}
                      isWithinText={false}
                      data-testid={`todo-item-course-link-${item.plannable_id}`}
                    >
                      <Text size="small">{I18n.t('Go to course')}</Text>
                    </Link>
                  </Flex.Item>
                </Flex>
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
          <IconButton
            screenReaderLabel={`Mark ${item.plannable.title} as complete`}
            interaction="disabled"
            data-testid={`todo-checkbox-${item.plannable_id}`}
          >
            <IconCheckPlusLine />
          </IconButton>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default TodoItem
