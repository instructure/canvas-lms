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

import {genericError} from '../ApiResult'
import {matchApiResultState} from '../matchApiResultState'
import {WithApiResultState} from '../WithApiResultState'

test('it should render loaded values', () => {
  const state: WithApiResultState<number> = {
    _type: 'loaded',
    data: 1,
  }

  const result = matchApiResultState(state)<any>({
    data: (...args) => args,
    error: () => 0,
    loading: () => 0,
  })

  expect(result).toStrictEqual([1, false, undefined])
})

test('it should render not_requested values', () => {
  const state: WithApiResultState<number> = {
    _type: 'not_requested',
  }

  const result = matchApiResultState(state)<any>({
    data: (...args) => args,
    error: () => 0,
    loading: () => 1,
  })

  expect(result).toStrictEqual(1)
})

test('it should render reloading values', () => {
  const state: WithApiResultState<number> = {
    _type: 'reloading',
    requested: 123,
    data: 1,
  }

  const result = matchApiResultState(state)<any>({
    data: (...args) => args,
    error: () => 0,
    loading: () => 0,
  })

  expect(result).toStrictEqual([1, true, 123])
})

test('it should render stale values', () => {
  const state: WithApiResultState<number> = {
    _type: 'stale',
    data: 1,
  }

  const result = matchApiResultState(state)<any>({
    data: (...args) => args,
    error: () => 0,
    loading: () => 0,
  })

  expect(result).toStrictEqual([1, true, undefined])
})

test('it should render error values', () => {
  const state: WithApiResultState<number> = {
    _type: 'error',
    error: genericError('Erroar'),
  }

  const result = matchApiResultState(state)<any>({
    data: () => 0,
    error: (...args) => args,
    loading: () => 0,
  })

  expect(result).toStrictEqual([
    {
      _type: 'GenericError',
      message: 'Erroar',
    },
  ])
})
