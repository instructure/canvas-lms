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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {IconButton, CloseButton} from '@instructure/ui-buttons'
import {IconEyeLine, IconOffLine, IconMoreLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import ColorPicker from '@canvas/color-picker'
import instFSOptimizedImageUrl from '@canvas/dashboard-card/util/instFSOptimizedImageUrl'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import type {CourseGradeCardProps} from '../../../types'
import {convertToLetterGrade, getAccessibleTextColor} from './utils'
import {useWidgetDashboard} from '../../../hooks/useWidgetDashboardContext'

const I18n = createI18nScope('widget_dashboard')

const DEFAULT_COURSE_COLOR = '#334451'

const CourseGradeCard: React.FC<CourseGradeCardProps> = ({
  courseId,
  courseCode,
  courseName,
  originalName,
  currentGrade,
  gradingScheme,
  lastUpdated,
  globalGradeVisibility = true,
  onGradeVisibilityChange,
  courseColor,
  term,
  image,
}) => {
  const {updateCourseColor, updateCourseNickname} = useWidgetDashboard()
  const isGradeVisible = globalGradeVisibility
  const [showMenu, setShowMenu] = useState(false)

  const handleNicknameChange = (nickname: string) => {
    updateCourseNickname(courseId, nickname)
  }

  const safeColor = courseColor ?? DEFAULT_COURSE_COLOR

  const textColor = getAccessibleTextColor(safeColor)
  const isLightText = textColor === '#FFFFFF'

  const handleToggleGrade = () => {
    const newVisibility = !isGradeVisible
    onGradeVisibilityChange?.(newVisibility)
  }

  const handleColorChange = (newColor: string) => {
    const colorWithHash = newColor.startsWith('#') ? newColor : `#${newColor}`
    updateCourseColor(courseId, colorWithHash)
  }

  const hasGrade = currentGrade !== null && currentGrade !== undefined

  const formatGradeDisplay = () => {
    if (!isGradeVisible) return '•••'
    if (currentGrade === null) return 'N/A'

    if (gradingScheme === 'percentage') {
      return `${Math.floor(currentGrade)}%`
    }

    if (Array.isArray(gradingScheme)) {
      return convertToLetterGrade(currentGrade, gradingScheme)
    }

    return `${Math.floor(currentGrade)}%`
  }

  const gradeOverlay = hasGrade && (
    <div
      style={{
        position: 'absolute',
        top: '0.75rem',
        left: '0.75rem',
        zIndex: 100,
      }}
    >
      <div
        style={{
          backgroundColor: isLightText ? 'rgba(0, 0, 0, 0.6)' : 'rgba(255, 255, 255, 0.85)',
          padding: '0.25rem 0.75rem',
          borderRadius: '1rem',
          display: 'flex',
          alignItems: 'center',
          gap: '0.25rem',
        }}
      >
        <Text
          size="x-large"
          weight="bold"
          themeOverride={{
            primaryInverseColor: textColor,
          }}
          color="primary-inverse"
          data-testid={`course-${courseId}-grade`}
        >
          {formatGradeDisplay()}
        </Text>
        <IconButton
          size="small"
          withBackground={false}
          withBorder={false}
          color={isLightText ? 'primary-inverse' : 'secondary'}
          screenReaderLabel={
            isGradeVisible
              ? I18n.t('Hide grade for %{courseName}', {courseName})
              : I18n.t('Show grade for %{courseName}', {courseName})
          }
          onClick={handleToggleGrade}
          data-testid={
            isGradeVisible
              ? `hide-single-grade-button-${courseId}`
              : `show-single-grade-button-${courseId}`
          }
        >
          {isGradeVisible ? <IconEyeLine /> : <IconOffLine />}
        </IconButton>
      </div>
    </div>
  )

  const settingsMenu = (
    <div
      style={{
        position: 'absolute',
        top: '0.75rem',
        right: '0.75rem',
        zIndex: 100,
      }}
    >
      <Popover
        on="click"
        isShowingContent={showMenu}
        onShowContent={() => setShowMenu(true)}
        onHideContent={() => setShowMenu(false)}
        shouldContainFocus={true}
        shouldReturnFocus={true}
        renderTrigger={
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            color={isLightText ? 'primary-inverse' : 'secondary'}
            screenReaderLabel={I18n.t('Course settings for %{courseName}', {courseName})}
          >
            <IconMoreLine />
          </IconButton>
        }
      >
        <View as="div" padding="small" width="190px">
          <CloseButton
            placement="end"
            onClick={() => setShowMenu(false)}
            screenReaderLabel={I18n.t('Close')}
          />
          <View as="div" padding="small 0 0 0">
            <Text size="small" weight="bold">
              {I18n.t('Card Color')}
            </Text>
          </View>
          <ColorPicker
            assetString={`course_${courseId}`}
            afterUpdateColor={handleColorChange}
            hidePrompt={true}
            nonModal={true}
            hideOnScroll={false}
            withAnimation={false}
            withBorder={false}
            withBoxShadow={false}
            withArrow={false}
            currentColor={safeColor}
            nicknameInfo={{
              nickname: courseName,
              originalName: originalName ?? courseName,
              courseId,
              onNicknameChange: handleNicknameChange,
            }}
            afterClose={() => setShowMenu(false)}
            parentComponent="CourseGradeCard"
            focusOnMount={false}
          />
        </View>
      </Popover>
    </div>
  )

  return (
    <View
      as="div"
      background="primary"
      borderRadius="medium"
      width="100%"
      height="100%"
      shadow="resting"
      role="listitem"
      aria-label={courseName}
      position="relative"
      data-testid={`course-grade-card-${courseId}`}
    >
      <Flex direction="column" width="100%" height="100%">
        <Flex.Item>
          {image ? (
            <div
              style={{
                position: 'relative',
                height: '146px',
                width: '100%',
                borderRadius: '0.5rem 0.5rem 0 0',
                backgroundImage: `url(${instFSOptimizedImageUrl(image, {x: 262, y: 146})})`,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
              }}
            >
              <div
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  backgroundColor: safeColor,
                  opacity: 0.6,
                  borderRadius: '0.5rem 0.5rem 0 0',
                }}
              />
              {gradeOverlay}
              {settingsMenu}
            </div>
          ) : (
            <View
              as="div"
              background="primary"
              height="146px"
              width="100%"
              borderRadius="0.5rem 0.5rem 0 0"
              position="relative"
              themeOverride={{
                backgroundPrimary: safeColor,
              }}
            >
              {gradeOverlay}
              {settingsMenu}
            </View>
          )}
        </Flex.Item>

        <Flex.Item padding="small" shouldGrow>
          <Flex direction="column" gap="xx-small">
            <View>
              <Text
                size="medium"
                weight="bold"
                themeOverride={{
                  fontWeightBold: 700,
                }}
                wrap="break-word"
                data-testid={`course-${courseId}-name`}
              >
                {courseName}
              </Text>
            </View>
            <View>
              <Text
                size="small"
                color="secondary"
                wrap="break-word"
                data-testid={`course-${courseId}-code`}
              >
                {courseCode}
              </Text>
            </View>
            {term && (
              <View>
                <Text
                  size="small"
                  color="secondary"
                  wrap="break-word"
                  data-testid={`course-${courseId}-term`}
                >
                  {term}
                </Text>
              </View>
            )}
            {hasGrade && lastUpdated && (
              <View>
                <Text
                  size="small"
                  color="secondary"
                  data-testid={`course-${courseId}-last-updated`}
                >
                  <FriendlyDatetime
                    dateTime={lastUpdated}
                    format={I18n.t('#date.formats.short')}
                    prefix={I18n.t('Updated')}
                  />
                </Text>
              </View>
            )}
          </Flex>
        </Flex.Item>

        <Flex.Item padding="0 small small small" overflowX="visible" overflowY="visible">
          <Flex wrap="wrap" gap="small" justifyItems="center">
            <Flex.Item overflowX="visible" overflowY="visible">
              <Link
                href={`/courses/${courseId}/grades`}
                isWithinText={false}
                aria-label={I18n.t('View %{courseName} gradebook', {courseName})}
                data-testid={`course-${courseId}-gradebook-link`}
              >
                <Text size="small">{I18n.t('View Gradebook')}</Text>
              </Link>
            </Flex.Item>
            <Flex.Item>
              <Text size="small" color="secondary">
                |
              </Text>
            </Flex.Item>
            <Flex.Item overflowX="visible" overflowY="visible">
              <Link
                href={`/courses/${courseId}`}
                isWithinText={false}
                aria-label={I18n.t('Go to %{courseName}', {courseName})}
                data-testid={`course-${courseId}-link`}
              >
                <Text size="small">{I18n.t('Go to Course')}</Text>
              </Link>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default CourseGradeCard
