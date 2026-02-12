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

import React, {useState, useMemo, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Avatar} from '@instructure/ui-avatar'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {List} from '@instructure/ui-list'
import {IconButton} from '@instructure/ui-buttons'
import {IconMessageLine} from '@instructure/ui-icons'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import MessageStudents from '@canvas/message-students-modal/react'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import PeopleFilters, {type RoleFilterOption, isValidRoleFilterOption} from './PeopleFilters'
import type {BaseWidgetProps} from '../../../types'
import {useCourseInstructorsPaginated} from '../../../hooks/useCourseInstructors'
import {DEFAULT_PAGE_SIZE} from '../../../constants/pagination'
import {useWidgetConfig} from '../../../hooks/useWidgetConfig'

const I18n = createI18nScope('widget_dashboard')

const PeopleWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isEditMode = false,
  isLoading: externalIsLoading,
  error: externalError,
  onRetry,
  dragHandleProps,
}) => {
  const [selectedCourse, setSelectedCourse] = useWidgetConfig<string>(
    widget.id,
    'selectedCourse',
    'all',
  )
  const [selectedRole, setSelectedRole] = useWidgetConfig<RoleFilterOption>(
    widget.id,
    'selectedRole',
    'all',
    isValidRoleFilterOption,
  )
  const [selectedRecipient, setSelectedRecipient] = useState<{
    id: string
    displayName: string
    email?: string
    contextCode: string
  } | null>(null)
  const [modalKey, setModalKey] = useState(0)

  const instructorCourseIds = useMemo(() => {
    if (selectedCourse === 'all') {
      return []
    }
    return [selectedCourse]
  }, [selectedCourse])

  const enrollmentTypes = useMemo(() => {
    if (selectedRole === 'all') {
      return undefined
    }
    return selectedRole === 'teacher' ? ['TeacherEnrollment'] : ['TaEnrollment']
  }, [selectedRole])

  const {
    currentPage,
    currentPageIndex,
    totalPages,
    goToPage,
    isLoading: instructorsLoading,
    isPaginationLoading: instructorsPaginationLoading,
    error: instructorsError,
  } = useCourseInstructorsPaginated({
    courseIds: instructorCourseIds,
    limit: DEFAULT_PAGE_SIZE.PEOPLE,
    enrollmentTypes,
  })

  const instructors = currentPage?.data ?? []

  const error =
    externalError ||
    (instructorsError ? I18n.t('Failed to load instructor data. Please try again.') : null)
  const isLoading = !error && (externalIsLoading || instructorsLoading)

  const handleOpenMessageModal = (instructor: any) => {
    const courseId = instructor.enrollments?.[0]?.course_id
    setSelectedRecipient({
      id: instructor.id.split('-')[0],
      displayName: instructor.name,
      email: instructor.email,
      contextCode: courseId ? `course_${courseId}` : '',
    })
    setModalKey(prev => prev + 1)
  }

  const handleCloseMessageModal = () => {
    setSelectedRecipient(null)
  }

  const handleCourseChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedCourse(data.value)
      }
    },
    [setSelectedCourse],
  )

  const handleRoleChange = useCallback(
    (_event: React.SyntheticEvent, data: {value?: string | number; id?: string}) => {
      if (data.value && typeof data.value === 'string') {
        setSelectedRole(data.value as RoleFilterOption)
      }
    },
    [setSelectedRole],
  )

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      dragHandleProps={dragHandleProps}
      isLoading={isLoading}
      error={error}
      onRetry={onRetry}
      loadingText={I18n.t('Loading people data...')}
      pagination={{
        currentPage: currentPageIndex + 1,
        totalPages,
        onPageChange: goToPage,
        ariaLabel: I18n.t('Instructors pagination'),
      }}
      loadingOverlay={{
        isLoading: instructorsPaginationLoading,
        ariaLabel: I18n.t('Loading instructors'),
      }}
    >
      <Flex direction="column" height="100%">
        <PeopleFilters
          selectedCourse={selectedCourse}
          selectedRole={selectedRole}
          onCourseChange={handleCourseChange}
          onRoleChange={handleRoleChange}
        />
        <Flex.Item shouldGrow>
          <View as="div" padding="small 0 0 0">
            {instructors.length === 0 ? (
              <Text color="secondary" data-testid="no-instructors-message">
                {I18n.t('No instructors found')}
              </Text>
            ) : (
              <View as="div">
                <List isUnstyled margin="0">
                  {instructors.map(instructor => (
                    <List.Item key={instructor.id} margin="0">
                      <Flex
                        gap="small"
                        padding="small 0"
                        role="group"
                        aria-label={instructor.name}
                        alignItems="start"
                      >
                        <Flex.Item>
                          <Avatar
                            name={instructor.name}
                            src={instructor.avatar_url}
                            size="medium"
                            data-testid={`instructor-avatar-${instructor.id}`}
                          />
                        </Flex.Item>
                        <Flex.Item shouldGrow shouldShrink>
                          <View as="div">
                            <Text
                              size="medium"
                              weight="bold"
                              wrap="break-word"
                              lineHeight="condensed"
                            >
                              {instructor.name}
                            </Text>
                            {instructor.email && (
                              <View as="div">
                                <Text size="small" wrap="break-word">
                                  {instructor.email}
                                </Text>
                              </View>
                            )}
                            {instructor.enrollments.length === 1 ? (
                              <>
                                <View as="div">
                                  <Text size="small" wrap="break-word">
                                    {instructor.course_name}
                                  </Text>
                                </View>
                                <View as="div">
                                  <Text size="small">
                                    {instructor.enrollments[0].type === 'TeacherEnrollment'
                                      ? I18n.t('Teacher')
                                      : I18n.t('Teaching Assistant')}
                                  </Text>
                                </View>
                              </>
                            ) : (
                              <View as="div" margin="xx-small 0 0 0">
                                <ToggleDetails
                                  summary={
                                    <Text size="small">
                                      {I18n.t(
                                        {
                                          one: '1 enrollment',
                                          other: '%{count} enrollments',
                                        },
                                        {count: instructor.enrollments.length},
                                      )}
                                    </Text>
                                  }
                                  size="small"
                                >
                                  <View as="div" borderWidth="small 0 0 0" padding="x-small 0 0 0">
                                    <View
                                      as="ul"
                                      margin="0"
                                      padding="0"
                                      elementRef={(el: any) => {
                                        if (el) {
                                          el.style.listStyleType = 'disc'
                                        }
                                      }}
                                    >
                                      {instructor.enrollments.map(enrollment => {
                                        const role =
                                          enrollment.type === 'TeacherEnrollment'
                                            ? I18n.t('Teacher')
                                            : I18n.t('Teaching Assistant')
                                        return (
                                          <li key={enrollment.id}>
                                            <Text size="small" wrap="break-word">
                                              {I18n.t('%{role} in %{course}', {
                                                role,
                                                course: enrollment.course_name,
                                              })}
                                            </Text>
                                          </li>
                                        )
                                      })}
                                    </View>
                                  </View>
                                </ToggleDetails>
                              </View>
                            )}
                          </View>
                        </Flex.Item>
                        <Flex.Item>
                          <View as="div" margin="0 small">
                            <IconButton
                              onClick={() => handleOpenMessageModal(instructor)}
                              screenReaderLabel={I18n.t('Send a message to %{instructor}', {
                                instructor: instructor.name,
                              })}
                              data-testid={`message-button-${instructor.id}`}
                            >
                              <IconMessageLine />
                            </IconButton>
                          </View>
                        </Flex.Item>
                      </Flex>
                    </List.Item>
                  ))}
                </List>
              </View>
            )}
          </View>
        </Flex.Item>
      </Flex>
      {selectedRecipient && (
        <MessageStudents
          key={modalKey}
          contextCode={selectedRecipient.contextCode}
          recipients={[selectedRecipient]}
          title={I18n.t('Send Message to %{name}', {name: selectedRecipient.displayName})}
          onRequestClose={handleCloseMessageModal}
        />
      )}
    </TemplateWidget>
  )
}

export default PeopleWidget
