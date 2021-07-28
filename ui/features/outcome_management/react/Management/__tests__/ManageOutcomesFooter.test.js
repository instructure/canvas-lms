/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import ManageOutcomesFooter from '../ManageOutcomesFooter'

describe('ManageOutcomesFooter', () => {
  let onRemoveHandlerMock
  let onMoveHandlerMock
  const generateOutcomes = (num, canUnlink) =>
    new Array(num).fill(0).reduce(
      (_val, idx) => ({
        [idx + 1]: {_id: `idx + 1`, title: `Outcome ${idx + 1}`, canUnlink}
      }),
      {}
    )
  const defaultProps = (numberToGenerate = 2, canUnlink = true) => ({
    selected: generateOutcomes(numberToGenerate, canUnlink),
    selectedCount: numberToGenerate,
    onRemoveHandler: onRemoveHandlerMock,
    onMoveHandler: onMoveHandlerMock
  })

  beforeEach(() => {
    onRemoveHandlerMock = jest.fn()
    onMoveHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('# of selected outcomes is enabled when selected props provided and ge 0 ', () => {
    const {getByText} = render(<ManageOutcomesFooter {...defaultProps()} />)
    expect(getByText('2 Outcomes Selected')).toBeInTheDocument()
    expect(getByText('2 Outcomes Selected').hasAttribute('aria-disabled')).toBe(false)
  })

  it('# selected outcomes is disabled when selected props provided and eq 0', () => {
    const {getByText} = render(<ManageOutcomesFooter {...defaultProps(0)} />)
    expect(getByText(`0 Outcomes Selected`).hasAttribute('aria-disabled')).toBe(true)
  })

  describe('Buttons and click handlers', () => {
    it('renders buttons enabled when selected props provided and gt 0 ', () => {
      const {getByText} = render(<ManageOutcomesFooter {...defaultProps()} />)
      expect(getByText('Remove').closest('button')).not.toHaveAttribute('disabled')
    })

    it('renders buttons disabled when selected props provided and eq 0 ', () => {
      const {getByText} = render(<ManageOutcomesFooter {...defaultProps(0)} />)
      expect(getByText('Remove').closest('button')).toHaveAttribute('disabled')
    })

    it('handles click on Remove button', () => {
      const {getByText} = render(<ManageOutcomesFooter {...defaultProps()} />)
      const btn = getByText('Remove')
      fireEvent.click(btn)
      expect(onRemoveHandlerMock).toHaveBeenCalledTimes(1)
    })

    it('handles click on Move button', () => {
      const {getByText} = render(<ManageOutcomesFooter {...defaultProps()} />)
      const btn = getByText('Move')
      fireEvent.click(btn)
      expect(onMoveHandlerMock).toHaveBeenCalledTimes(1)
    })
  })

  describe('Text pluralization', () => {
    it('handles properly pluralization if 1 Outcome Selected', () => {
      const {getByText} = render(<ManageOutcomesFooter {...defaultProps(1)} />)
      expect(getByText('1 Outcome Selected')).toBeInTheDocument()
    })

    it('handles properly pluralization if gt 1 Outcome Selected', () => {
      const {getByText} = render(<ManageOutcomesFooter {...defaultProps(2)} />)
      expect(getByText('2 Outcomes Selected')).toBeInTheDocument()
    })
  })
})
