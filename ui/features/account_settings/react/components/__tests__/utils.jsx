/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {Provider} from 'react-redux'
import {render} from '@testing-library/react'
import {configStore} from '../../store'

const fakeAxios = {
  delete: jest.fn(() => ({then() {}})),
  get: jest.fn(() => ({then() {}})),
  post: jest.fn(() => ({
    then() {
      return {then() {}}
    },
  })),
  put: jest.fn(() => ({then() {}})),
}

// This is modified from a version by Kent C. Dodds described here:
// https://github.com/kentcdodds/@testing-library/react/blob/master/examples/__tests__/react-redux.js
export function renderWithRedux(
  ui,
  {
    initialState,
    store = configStore(initialState, fakeAxios, {
      disableLogger: true,
    }),
  } = {}
) {
  return {
    ...render(<Provider store={store}>{ui}</Provider>),
    store,
  }
}
