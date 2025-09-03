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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import {formatDueDate, getTypeIcon} from './utils'
import type {CourseWorkItem as CourseWorkItemType} from '../../../hooks/useCourseWork'

const I18n = createI18nScope('widget_dashboard')

interface CourseWorkItemProps {
  item: CourseWorkItemType
}

export function CourseWorkItem({item}: CourseWorkItemProps) {
  return (
    <Flex.Item key={item.id} overflowY="hidden">
      <View as="div" margin="small" background="primary">
        <Flex gap="small" alignItems="start">
          <Flex.Item shouldShrink>
            <View
              as="div"
              background="secondary"
              borderRadius="medium"
              padding="medium"
              margin="0 0 x-small 0"
              display="inline-block"
              themeOverride={{
                backgroundSecondary: '#e3f2fd',
              }}
            >
              {getTypeIcon(item.type)}
            </View>
          </Flex.Item>
          <Flex.Item shouldGrow>
            <Flex direction="column" gap="xx-small">
              <Link
                href={item.htmlUrl}
                isWithinText={false}
                data-testid={`course-work-item-link-${item.id}`}
              >
                <Text weight="bold" size="small">
                  {item.title}
                </Text>
              </Link>
              <Text size="x-small" color="secondary">
                {item.course.name}
              </Text>
              <Text size="x-small" color="secondary">
                {formatDueDate(item.dueAt)}
                {item.points != null && ` • ${I18n.t('%{points} pts', {points: item.points})}`}
              </Text>
            </Flex>
          </Flex.Item>
        </Flex>
      </View>
    </Flex.Item>
  )
}
