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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Button} from '@instructure/ui-buttons'
import type {CourseGradeCardProps} from '../../../types'
import {formatUpdatedDate, convertToLetterGrade} from './utils'
import {CourseCode} from '../../shared/CourseCode'

const I18n = createI18nScope('widget_dashboard')

const CourseGradeCard: React.FC<CourseGradeCardProps> = ({
  courseId,
  courseCode,
  courseName,
  currentGrade,
  gradingScheme,
  lastUpdated,
  gridIndex,
  globalGradeVisibility = true,
  onGradeVisibilityChange,
}) => {
  // Use the global visibility state instead of local state
  const isGradeVisible = globalGradeVisibility

  const handleToggleGrade = () => {
    const newVisibility = !isGradeVisible
    onGradeVisibilityChange?.(newVisibility)
  }

  return (
    <View
      as="div"
      background="secondary"
      borderRadius="medium"
      borderColor="secondary"
      padding="x-small"
      width="100%"
      shadow="resting"
      display="flex"
      overflowX="hidden"
      overflowY="hidden"
      role="listitem"
      aria-label={courseName}
    >
      <Flex direction="column" width="100%" height="100%">
        <Flex.Item padding="0" margin="0 0 small 0" overflowX="visible" overflowY="visible">
          <CourseCode
            courseId={courseId}
            overrideCode={courseCode}
            gridIndex={gridIndex}
            size="x-small"
            maxWidth="14rem"
          />
        </Flex.Item>

        <Flex.Item height="3rem" padding="0 0 0 xx-small">
          <View height="100%" overflowY="hidden">
            <Text size="medium" weight="bold" lineHeight="condensed">
              {courseName}
            </Text>
          </View>
        </Flex.Item>

        <Flex.Item shouldGrow padding="0 0 0 xx-small" overflowY="visible">
          <Flex direction="column" gap="0">
            <Flex.Item>
              <Text size="small" color="secondary">
                {formatUpdatedDate(lastUpdated)}
              </Text>
            </Flex.Item>
            <Flex.Item overflowX="visible" overflowY="visible">
              <Link
                href={`/courses/${courseId}/grades`}
                isWithinText={false}
                aria-label={I18n.t('View %{courseName} gradebook', {courseName})}
              >
                <Text size="small">{I18n.t('View gradebook')}</Text>
              </Link>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item width="100%" height="5rem">
          <Flex direction="row" justifyItems="start" alignItems="center" height="100%">
            <Flex.Item shouldGrow padding="0 0 0 xx-small">
              <Button
                color="secondary"
                size="small"
                onClick={handleToggleGrade}
                aria-pressed={!isGradeVisible}
                aria-label={
                  isGradeVisible
                    ? I18n.t('Hide grades for %{courseName}', {courseName})
                    : I18n.t('Show grades for %{courseName}', {courseName})
                }
              >
                {isGradeVisible ? I18n.t('Hide grade') : I18n.t('Show grade')}
              </Button>
            </Flex.Item>
            <Flex.Item>
              {isGradeVisible && (
                <Text size="xx-large" weight="bold">
                  {currentGrade !== null
                    ? gradingScheme === 'percentage'
                      ? `${Math.floor(currentGrade)}%`
                      : convertToLetterGrade(currentGrade, gradingScheme)
                    : 'N/A'}
                </Text>
              )}
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default CourseGradeCard
