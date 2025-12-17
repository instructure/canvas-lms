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

import React, {useMemo, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import TodoItem from './TodoItem'
import CreateTodoModal from './CreateTodoModal'
import type {BaseWidgetProps} from '../../../types'
import {usePlannerItems} from './hooks/usePlannerItems'
import {useCreatePlannerNote} from './hooks/useCreatePlannerNote'
import {useWidgetDashboard} from '../../../hooks/useWidgetDashboardContext'

const I18n = createI18nScope('widget_dashboard')

type TodoFilter = 'incomplete_items' | 'complete_items' | undefined

const TodoListWidget: React.FC<BaseWidgetProps> = ({widget, isEditMode = false}) => {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [filter, setFilter] = useState<TodoFilter>('incomplete_items')

  const dateRange = useMemo(() => {
    const twoWeeksAgo = new Date()
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14)

    const oneYearFromNow = new Date()
    oneYearFromNow.setFullYear(oneYearFromNow.getFullYear() + 1)

    return {
      startDate: twoWeeksAgo.toISOString(),
      endDate: oneYearFromNow.toISOString(),
    }
  }, [])

  const {
    currentPage,
    currentPageIndex,
    totalPages,
    goToPage,
    isLoading,
    error,
    refetch,
    resetPagination,
  } = usePlannerItems({
    perPage: 5,
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    filter,
  })

  // Reset pagination when filter changes
  React.useEffect(() => {
    resetPagination()
  }, [filter, resetPagination])

  const {mutate: createPlannerNote, isPending: isCreating} = useCreatePlannerNote()
  const {sharedCourseData} = useWidgetDashboard()

  const handleCreateTodo = (data: {
    title: string
    todo_date: string
    details?: string
    course_id?: string
  }) => {
    createPlannerNote(data, {
      onSuccess: () => {
        setIsModalOpen(false)
        showFlashAlert({
          message: I18n.t('To-do item created successfully'),
          type: 'success',
        })
      },
      onError: () => {
        showFlashAlert({
          message: I18n.t('Failed to create to-do item. Please try again.'),
          type: 'error',
        })
      },
    })
  }

  // Transform shared course data to the format expected by CreateTodoModal
  const courses = useMemo(
    () =>
      sharedCourseData.map(course => ({
        id: course.courseId,
        longName: course.courseName,
        is_student: true,
      })),
    [sharedCourseData],
  )

  const locale = window.ENV?.LOCALE || 'en'
  const timeZone = window.ENV?.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone

  const renderContent = () => {
    return (
      <View as="div">
        <View as="div" padding="small 0" borderWidth="0 0 small 0">
          <SimpleSelect
            renderLabel={I18n.t('Filter')}
            value={filter || 'all'}
            onChange={(_e, {value}) => {
              setFilter(value === 'all' ? undefined : (value as TodoFilter))
            }}
            width="200px"
            data-testid="todo-filter-select"
          >
            <SimpleSelect.Option id="incomplete" value="incomplete_items">
              {I18n.t('Incomplete')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="complete" value="complete_items">
              {I18n.t('Complete')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="all" value="all">
              {I18n.t('All')}
            </SimpleSelect.Option>
          </SimpleSelect>
        </View>

        {currentPage.length === 0 ? (
          <View as="div" textAlign="center" padding="large 0">
            <Text color="secondary" size="medium" data-testid="no-todos-message">
              {I18n.t('No upcoming items')}
            </Text>
          </View>
        ) : (
          <View as="div">
            <List isUnstyled margin="0">
              {currentPage.map(item => (
                <List.Item key={`${item.plannable_type}-${item.plannable_id}`} margin="0">
                  <TodoItem item={item} />
                </List.Item>
              ))}
            </List>
          </View>
        )}
      </View>
    )
  }

  return (
    <>
      <TemplateWidget
        widget={widget}
        isEditMode={isEditMode}
        isLoading={isLoading}
        error={error ? I18n.t('Failed to load to-do items. Please try again.') : null}
        onRetry={refetch}
        loadingText={I18n.t('Loading to-do items...')}
        headerActions={
          <Button size="small" onClick={() => setIsModalOpen(true)} data-testid="new-todo-button">
            {I18n.t('+ New')}
          </Button>
        }
        pagination={{
          currentPage: currentPageIndex + 1,
          totalPages,
          onPageChange: goToPage,
          isLoading,
          ariaLabel: I18n.t('To-do list pagination'),
        }}
      >
        {renderContent()}
      </TemplateWidget>
      <CreateTodoModal
        open={isModalOpen}
        onDismiss={() => setIsModalOpen(false)}
        onSubmit={handleCreateTodo}
        isCreating={isCreating}
        courses={courses}
        locale={locale}
        timeZone={timeZone}
      />
    </>
  )
}

export default TodoListWidget
