/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'
import useFetchApi from '@canvas/use-fetch-api-hook'
import EmptyTodos from './EmptyTodos'

import Todo, {getBaseDueAt} from './Todo'

const I18n = useI18nScope('todos_page')

// Sort to-dos based on the assignment's base due date (aka the "Everyone else"
// override when there are multiple due dates, putting those with no due date last
export const sortTodos = (t1, t2) => {
  const d1 = t1.assignment && getBaseDueAt(t1.assignment)
  const d2 = t2.assignment && getBaseDueAt(t2.assignment)
  if (d1 === d2) return 0
  if (!d1) return 1
  if (!d2) return -1
  return d1.localeCompare(d2)
}

export const TodosPage = ({timeZone, visible, openTodosInNewTab}) => {
  const [loading, setLoading] = useState(true)
  const [todos, setTodos] = useState(null)

  useFetchApi(
    {
      path: '/api/v1/users/self/todo',
      success: useCallback(data => {
        if (data) {
          setTodos(data.filter(todo => todo.type === 'grading').sort(sortTodos))
          setLoading(false)
        }
      }, []),
      error: useCallback(showFlashError(I18n.t('Failed to load todos')), []),
      forceResult: visible && !todos ? undefined : false,
      params: {
        per_page: '100',
      },
    },
    [visible]
  )

  const todoSkeleton = props => (
    <div data-testid="todo-loading-skeleton" {...props}>
      <LoadingSkeleton
        screenReaderLabel={I18n.t('Loading Todo Title')}
        margin="medium 0 0 large"
        height="1.2rem"
        width="27rem"
      />
      <LoadingSkeleton
        screenReaderLabel={I18n.t('Loading Todo Course Name')}
        margin="x-small 0 0 large"
        height="1.1rem"
        width="8rem"
      />
      <LoadingSkeleton
        screenReaderLabel={I18n.t('Loading Additional Todo Details')}
        margin="x-small 0 large large"
        height="1.1rem"
        width="16rem"
      />
    </div>
  )

  return (
    <section
      id="dashboard_page_todos"
      style={{display: visible ? 'block' : 'none'}}
      aria-hidden={!visible}
    >
      <LoadingWrapper
        id="homeroom-todos"
        isLoading={loading}
        renderCustomSkeleton={todoSkeleton}
        skeletonsNum={todos?.length}
        defaultSkeletonsNum={5}
        allowZeroSkeletons={false}
      >
        {todos?.length > 0 ? (
          todos.map(todo => (
            <Todo
              key={`todo-assignment-${todo.assignment?.id}`}
              timeZone={timeZone}
              openInNewTab={openTodosInNewTab}
              {...todo}
            />
          ))
        ) : (
          <EmptyTodos />
        )}
      </LoadingWrapper>
    </section>
  )
}

TodosPage.propTypes = {
  timeZone: PropTypes.string.isRequired,
  visible: PropTypes.bool.isRequired,
  openTodosInNewTab: PropTypes.bool.isRequired,
}
