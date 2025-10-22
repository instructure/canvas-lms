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
import {getSubmissionStatus, getTypeIcon} from '../widgets/CourseWorkWidget/utils'
import type {CourseWorkItem as CourseWorkItemType} from '../../hooks/useCourseWork'
import {useResponsiveContext} from '../../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

interface CourseWorkItemProps {
  item: CourseWorkItemType
}

export function CourseWorkItem({item}: CourseWorkItemProps) {
  const submissionStatus = getSubmissionStatus(item.late, item.missing, item.state, item.dueAt)
  const {isMobile} = useResponsiveContext()

  return (
    <Flex.Item key={item.id} overflowY="hidden" role="group" aria-label={item.title}>
      <View as="div" margin="small" background="primary">
        <Flex
          gap="small"
          alignItems={isMobile ? 'start' : 'center'}
          direction={isMobile ? 'column' : 'row'}
        >
          {!isMobile && (
            <Flex.Item>
              <View
                as="div"
                background="secondary"
                borderRadius="medium"
                padding={isMobile ? 'small' : 'medium'}
                margin="0 0 0 0"
                themeOverride={{
                  backgroundSecondary: submissionStatus.color.background,
                }}
              >
                {getTypeIcon(item.type, isMobile)}
              </View>
            </Flex.Item>
          )}
          <Flex.Item shouldGrow shouldShrink>
            <Flex direction="column" gap="0">
              <Flex.Item>
                <Link
                  href={item.htmlUrl}
                  isWithinText={false}
                  data-testid={`course-work-item-link-${item.id}`}
                >
                  <Text weight="bold" size="small">
                    {item.title}
                  </Text>
                </Link>
              </Flex.Item>
              <Flex.Item>
                <Text size="x-small" color="secondary">
                  {item.course.name}
                </Text>
              </Flex.Item>
              <Flex.Item>
                <Text size="x-small" color="secondary">
                  {item.points != null && `${I18n.t('%{points} pts', {points: item.points})}`}
                </Text>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item>
            <View
              as="span"
              background="primary"
              borderRadius="large"
              padding="x-small"
              display="inline-block"
              themeOverride={{backgroundPrimary: submissionStatus.color.background}}
            >
              <Flex gap="xx-small" alignItems="center">
                {submissionStatus.icon && (
                  <submissionStatus.icon size="x-small" color={submissionStatus.iconColor} />
                )}
                <Text
                  size="x-small"
                  weight="bold"
                  color="primary"
                  lineHeight="fit"
                  themeOverride={{
                    primaryColor: submissionStatus.color.textColor,
                  }}
                >
                  {submissionStatus.label}
                </Text>
              </Flex>
            </View>
          </Flex.Item>
        </Flex>
      </View>
    </Flex.Item>
  )
}
