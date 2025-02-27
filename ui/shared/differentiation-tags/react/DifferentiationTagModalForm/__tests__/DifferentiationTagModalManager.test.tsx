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
import {useDifferentiationTagCategoriesIndex} from '../../hooks/useDifferentiationTagCategoriesIndex'
import DifferentiationTagModalForm from '../DifferentiationTagModalForm'

jest.mock('../../hooks/useDifferentiationTagCategoriesIndex', () => ({
  useDifferentiationTagCategoriesIndex: jest.fn(),
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

  const renderComponent = (props: Partial<DifferentiationTagModalManagerProps> = {}) =>
    render(<DifferentiationTagModalManager {...defaultProps} {...props} />)

  beforeAll(() => {
    const globalEnv = global as any
    globalEnv.ENV = {course: {id: '456'}}
  })

  beforeEach(() => {
    jest.clearAllMocks()

    const mockUseDifferentiationTagCategoriesIndex =
      useDifferentiationTagCategoriesIndex as jest.Mock
    mockUseDifferentiationTagCategoriesIndex.mockReturnValue({data: undefined})

    const mockDifferentiationTagModalForm = DifferentiationTagModalForm as jest.Mock
    mockDifferentiationTagModalForm.mockClear()
  })

  it('calls useDifferentiationTagCategoriesIndex with course id and true', () => {
    renderComponent()
    expect(useDifferentiationTagCategoriesIndex).toHaveBeenCalledWith(456, {
      enabled: true,
      includeDifferentiationTags: true,
    })
  })

  describe('edit mode', () => {
    it('passes the correct tag set when category exists', () => {
      const mockCategories = [
        {id: 123, name: 'Category 123', extraField: 'ignore'},
        {id: 456, name: 'Category 456', extraField: 'ignore'},
      ]
      const mockFn = useDifferentiationTagCategoriesIndex as jest.Mock
      mockFn.mockReturnValue({data: mockCategories})
      renderComponent({mode: 'edit', differentiationTagCategoryId: 123})

      expect(DifferentiationTagModalForm).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: 'edit',
          differentiationTagSet: expect.objectContaining({id: 123, name: 'Category 123'}),
          categories: [
            {id: 123, name: 'Category 123'},
            {id: 456, name: 'Category 456'},
          ],
        }),
        expect.anything(),
      )
    })

    it('strips groups from categories prop but passes full object as differentiationTagSet in edit mode', () => {
      const mockCategories = [
        {id: 101, name: 'Category 101', groups: ['groupA', 'groupB']},
        {id: 202, name: 'Category 202', groups: ['groupC', 'groupD']},
      ]

      const mockFn = useDifferentiationTagCategoriesIndex as jest.Mock
      mockFn.mockReturnValue({data: mockCategories})

      renderComponent({mode: 'edit', differentiationTagCategoryId: 101})

      expect(DifferentiationTagModalForm).toHaveBeenCalledWith(
        expect.objectContaining({
          categories: [
            {id: 101, name: 'Category 101'},
            {id: 202, name: 'Category 202'},
          ],
          differentiationTagSet: expect.objectContaining({
            id: 101,
            name: 'Category 101',
            groups: ['groupA', 'groupB'],
          }),
        }),
        expect.anything(),
      )
    })

    it('passes undefined tag set when category is not found', () => {
      const mockCategories = [
        {id: 999, name: 'Category 999'},
        {id: 456, name: 'Category 456'},
      ]

      const mockFn = useDifferentiationTagCategoriesIndex as jest.Mock
      mockFn.mockReturnValue({data: mockCategories})

      renderComponent({mode: 'edit', differentiationTagCategoryId: 123})

      expect(DifferentiationTagModalForm).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: 'edit',
          differentiationTagSet: undefined,
          categories: [
            {id: 999, name: 'Category 999'},
            {id: 456, name: 'Category 456'},
          ],
        }),
        expect.anything(),
      )
    })
  })

  describe('create mode', () => {
    it('does not pass a tag set to the form', () => {
      const mockCategories = [{id: 789, name: 'Category 789'}]
      const mockFn = useDifferentiationTagCategoriesIndex as jest.Mock
      mockFn.mockReturnValue({data: mockCategories})

      renderComponent({mode: 'create'})

      expect(DifferentiationTagModalForm).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: 'create',
          differentiationTagSet: undefined,
          categories: [{id: 789, name: 'Category 789'}],
        }),
        expect.anything(),
      )
    })
  })

  it('passes common props (isOpen and onClose) to the form', () => {
    const mockCategories = [{id: 111, name: 'Category 111'}]
    const mockFn = useDifferentiationTagCategoriesIndex as jest.Mock
    mockFn.mockReturnValue({data: mockCategories})

    renderComponent({isOpen: false, onClose: onCloseMock})

    expect(DifferentiationTagModalForm).toHaveBeenCalledWith(
      expect.objectContaining({
        isOpen: false,
        onClose: onCloseMock,
      }),
      expect.anything(),
    )
  })
})
