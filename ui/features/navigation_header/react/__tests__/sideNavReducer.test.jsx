// Copyright (C) 2024 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React, {useReducer} from 'react'
import {render, fireEvent} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import {sideNavReducer} from '../utils'

const initialState = {
  isTrayOpen: false,
  activeTray: null,
  selectedNavItem: '',
  previousSelectedNavItem: '',
}

// Test component that uses useReducer with sideNavReducer
const TestComponent = () => {
  const [state, dispatch] = useReducer(sideNavReducer, initialState)

  return (
    <div>
      <div data-testid="isTrayOpen">{state.isTrayOpen.toString()}</div>
      <div data-testid="activeTray">{state.activeTray}</div>
      <div data-testid="selectedNavItem">{state.selectedNavItem}</div>
      <div data-testid="previousSelectedNavItem">{state.previousSelectedNavItem}</div>
      <button type="button" onClick={() => dispatch({type: 'SET_ACTIVE_TRAY', payload: 'courses'})}>
        Set Active Tray
      </button>
      <button
        type="button"
        onClick={() => dispatch({type: 'SET_SELECTED_NAV_ITEM', payload: 'dashboard'})}
      >
        Set Selected Nav Item
      </button>
      <button type="button" onClick={() => dispatch({type: 'SET_IS_TRAY_OPEN', payload: true})}>
        Open Tray
      </button>
      <button type="button" onClick={() => dispatch({type: 'RESET_ACTIVE_TRAY'})}>
        Reset Active Tray
      </button>
    </div>
  )
}

test('it handles SET_ACTIVE_TRAY action', () => {
  const {getByText, getByTestId} = render(<TestComponent />)

  fireEvent.click(getByText('Set Active Tray'))

  expect(getByTestId('isTrayOpen')).toHaveTextContent('true')
  expect(getByTestId('activeTray')).toHaveTextContent('courses')
  expect(getByTestId('previousSelectedNavItem')).toHaveTextContent('')
})

test('it handles SET_SELECTED_NAV_ITEM action', () => {
  const {getByText, getByTestId} = render(<TestComponent />)

  fireEvent.click(getByText('Set Selected Nav Item'))

  expect(getByTestId('selectedNavItem')).toHaveTextContent('dashboard')
})

test('it handles SET_IS_TRAY_OPEN action', () => {
  const {getByText, getByTestId} = render(<TestComponent />)

  fireEvent.click(getByText('Open Tray'))

  expect(getByTestId('isTrayOpen')).toHaveTextContent('true')
})

test('it handles RESET_ACTIVE_TRAY action', () => {
  const {getByText, getByTestId} = render(<TestComponent />)

  fireEvent.click(getByText('Set Active Tray'))
  fireEvent.click(getByText('Set Selected Nav Item'))
  fireEvent.click(getByText('Reset Active Tray'))

  expect(getByTestId('activeTray')).toHaveTextContent('')
  expect(getByTestId('selectedNavItem')).toHaveTextContent('')
  expect(getByTestId('previousSelectedNavItem')).toHaveTextContent('')
})
