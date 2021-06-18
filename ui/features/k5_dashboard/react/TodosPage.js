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
import I18n from 'i18n!todos_page'

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'
import useFetchApi from '@canvas/use-fetch-api-hook'

import Todo from './Todo'

export const TodosPage = ({timeZone, visible}) => {
  const [loading, setLoading] = useState(true)
  const [todos, setTodos] = useState(null)

  useFetchApi(
    {
      path: '/api/v1/users/self/todo',
      success: useCallback(data => {
        if (data) {
          setTodos(data)
          setLoading(false)
        }
      }, []),
      error: useCallback(showFlashError(I18n.t('Failed to load todos')), []),
      forceResult: visible && !todos ? undefined : false,
      params: {
        per_page: '100'
      }
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
        skeletonsCount={5}
      >
        {todos?.map(todo => (
          <Todo key={`todo-assignment-${todo.assignment?.id}`} timeZone={timeZone} {...todo} />
        ))}
      </LoadingWrapper>
    </section>
  )
}

TodosPage.propTypes = {
  timeZone: PropTypes.string.isRequired,
  visible: PropTypes.bool.isRequired
}

export default TodosPage
