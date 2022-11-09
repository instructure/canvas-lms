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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import MemoizedEquationEditorToolbar from '../index'
import buttons from '../buttons'

function defaultProps() {
  return {
    executeCommand: () => {},
  }
}

function renderToolbar(overrideProps = {}) {
  const props = defaultProps()
  return render(<MemoizedEquationEditorToolbar {...props} {...overrideProps} />)
}

describe('MemoizedEquationEditorToolbar', () => {
  it('renders all buttons', () => {
    const {container, getByText} = renderToolbar()

    buttons.forEach(tab => {
      fireEvent.click(getByText(tab.name))
      const count = container.querySelectorAll('button[type="button"]').length
      expect(count).toEqual(tab.commands.length)
    })
  })

  it('calls executeCommand on button click', () => {
    const mockFn = jest.fn()
    const {container, getByText} = renderToolbar({executeCommand: mockFn})
    const tabPanel = getByText('Basic')
    fireEvent.click(tabPanel)
    const button = container.querySelector('button[type="button"]')
    fireEvent.click(button)
    expect(mockFn).toHaveBeenCalled()
  })
})
