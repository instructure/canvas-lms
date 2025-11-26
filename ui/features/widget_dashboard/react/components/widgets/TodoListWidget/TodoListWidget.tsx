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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import TodoItem from './TodoItem'
import type {BaseWidgetProps} from '../../../types'
import {usePlannerItems} from './hooks/usePlannerItems'

const I18n = createI18nScope('widget_dashboard')

const TodoListWidget: React.FC<BaseWidgetProps> = ({widget, isEditMode = false}) => {
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

  const {currentPage, currentPageIndex, totalPages, goToPage, isLoading, error, refetch} =
    usePlannerItems({
      perPage: 5,
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    })

  const renderContent = () => {
    if (currentPage.length === 0) {
      return (
        <View as="div" textAlign="center" padding="large 0">
          <Text color="secondary" size="medium" data-testid="no-todos-message">
            {I18n.t('No upcoming items')}
          </Text>
        </View>
      )
    }

    return (
      <View as="div">
        <List isUnstyled margin="0">
          {currentPage.map(item => (
            <List.Item key={`${item.plannable_type}-${item.plannable_id}`} margin="0">
              <TodoItem item={item} />
            </List.Item>
          ))}
        </List>
      </View>
    )
  }

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load to-do items. Please try again.') : null}
      onRetry={refetch}
      loadingText={I18n.t('Loading to-do items...')}
      headerActions={
        <Button size="small" disabled data-testid="new-todo-button">
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
  )
}

export default TodoListWidget
