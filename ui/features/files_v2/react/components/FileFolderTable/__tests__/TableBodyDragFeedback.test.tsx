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

import {screen, fireEvent} from '@testing-library/react'
import {FAKE_FILES} from '../../../../fixtures/fakeData'
import {renderComponent} from './testUtils'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('TableBody drag feedback', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.querySelectorAll('body > div:not(#fixtures)').forEach(el => el.remove())
  })

  function createDataTransfer() {
    const data: Record<string, string> = {}
    return {
      setData: (type: string, val: string) => {
        data[type] = val
      },
      getData: (type: string) => data[type] ?? '',
      setDragImage: vi.fn(),
      effectAllowed: 'none',
      get types() {
        return Object.keys(data)
      },
    }
  }

  function fireDragStart() {
    const row = screen.getAllByTestId('table-row')[0]
    fireEvent.dragStart(row, {dataTransfer: createDataTransfer()})
  }

  function fireDragEnd() {
    const row = screen.getAllByTestId('table-row')[0]
    fireEvent.dragEnd(row)
  }

  it('renders and removes drag feedback', () => {
    renderComponent({rows: [FAKE_FILES[0]]})
    fireDragStart()
    expect(document.querySelector('.DragFeedback')).toBeInTheDocument()
    fireDragEnd()
    expect(document.querySelector('.DragFeedback')).not.toBeInTheDocument()
  })
})
