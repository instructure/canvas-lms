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

import React from 'react'
import {render} from '@testing-library/react'
import DifferentiationTagModalManager from '../DifferentiationTagModalManager'
import type {DifferentiationTagModalManagerProps} from '../DifferentiationTagModalManager'
import {useDifferentiationTagSet} from '../../hooks/useDifferentiationTagSet'
import DifferentiationTagModalForm from '../DifferentiationTagModalForm'

jest.mock('../../hooks/useDifferentiationTagSet', () => ({
  useDifferentiationTagSet: jest.fn(),
}))

jest.mock('../DifferentiationTagModalForm', () => ({
  __esModule: true,
  default: jest.fn(() => null),
}))

describe('DifferentiationTagModalManager', () => {
  const onCloseMock = jest.fn()
  const defaultProps: DifferentiationTagModalManagerProps = {
    isOpen: true,
    onClose: onCloseMock,
    mode: 'create',
  }

  const renderComponent = (props: Partial<DifferentiationTagModalManagerProps> = {}) => {
    render(<DifferentiationTagModalManager {...defaultProps} {...props} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
    ;(useDifferentiationTagSet as jest.Mock).mockReturnValue({data: undefined})
    ;(DifferentiationTagModalForm as jest.Mock).mockClear()
  })

  describe('edit mode', () => {
    it('fetches tag set using provided category ID', () => {
      const categoryId = 123
      renderComponent({mode: 'edit', differentiationTagCategoryId: categoryId})
      expect(useDifferentiationTagSet).toHaveBeenCalledWith(categoryId, true)
    })

    it('passes fetched tag set to form', () => {
      const mockTagSet = {id: '1', name: 'Test Set', groups: []}
      ;(useDifferentiationTagSet as jest.Mock).mockReturnValue({data: mockTagSet})

      renderComponent({mode: 'edit', differentiationTagCategoryId: 123})

      expect(DifferentiationTagModalForm).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: 'edit',
          differentiationTagSet: mockTagSet,
        }),
        expect.anything(),
      )
    })
  })

  describe('create mode', () => {
    it('does not fetch specific tag set', () => {
      renderComponent({mode: 'create'})
      expect(useDifferentiationTagSet).toHaveBeenCalledWith(undefined, true)
    })

    it('does not pass tag set to form', () => {
      renderComponent({mode: 'create'})
      expect(DifferentiationTagModalForm).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: 'create',
          differentiationTagSet: undefined,
        }),
        expect.anything(),
      )
    })
  })

  it('passes common props to form', () => {
    renderComponent()
    expect(DifferentiationTagModalForm).toHaveBeenCalledWith(
      expect.objectContaining({
        isOpen: true,
        onClose: onCloseMock,
        mode: 'create',
      }),
      expect.anything(),
    )
  })
})
