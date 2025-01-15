/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import ContentFilter from '@canvas/gradebook-content-filters/react/ContentFilter'

describe('ContentFilter', () => {
  const defaultProps = {
    allItemsId: 'all',
    allItemsLabel: 'All Items',
    disabled: false,
    items: [
      {id: '1', name: 'Item 1'},
      {id: '2', name: 'Item 2'},
    ],
    label: 'Example Filter',
    onSelect: jest.fn(),
    selectedItemId: 'all',
  }

  const renderContentFilter = (props = {}) => {
    return render(<ContentFilter {...defaultProps} {...props} />)
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('labels the filter using the given label', () => {
    renderContentFilter()
    expect(screen.getByRole('combobox', {name: 'Example Filter'})).toBeInTheDocument()
  })

  it('displays the label of the selected item as the value', () => {
    renderContentFilter({selectedItemId: '2'})
    const combobox = screen.getByRole('combobox', {name: 'Example Filter'})
    expect(combobox).toHaveDisplayValue('Item 2')
  })

  it('displays "All Items" as the value when selected', () => {
    renderContentFilter()
    const combobox = screen.getByRole('combobox', {name: 'Example Filter'})
    expect(combobox).toHaveDisplayValue('All Items')
  })

  describe('options list', () => {
    it('includes an option for each item plus the "all items" option', async () => {
      const user = userEvent.setup()
      renderContentFilter()
      await user.click(screen.getByRole('combobox', {name: 'Example Filter'}))
      const options = await screen.findAllByRole('option')
      expect(options).toHaveLength(defaultProps.items.length + 1)
    })

    it('labels the "all items" option using the given allItemsLabel', async () => {
      const user = userEvent.setup()
      renderContentFilter()
      await user.click(screen.getByRole('combobox', {name: 'Example Filter'}))
      expect(await screen.findByRole('option', {name: 'All Items'})).toBeInTheDocument()
    })

    it('labels each item option using the related item name', async () => {
      const user = userEvent.setup()
      renderContentFilter()
      await user.click(screen.getByRole('combobox', {name: 'Example Filter'}))
      expect(await screen.findByRole('option', {name: 'Item 1'})).toBeInTheDocument()
      expect(await screen.findByRole('option', {name: 'Item 2'})).toBeInTheDocument()
    })

    describe('when sortAlphabetically is enabled', () => {
      const items = [
        {id: '2', name: 'Item 2'},
        {id: '1', name: 'Item 1'},
      ]

      it('labels each item option using the related item name in alphabetical order', async () => {
        const user = userEvent.setup()
        renderContentFilter({sortAlphabetically: true, items})
        await user.click(screen.getByRole('combobox', {name: 'Example Filter'}))
        const options = await screen.findAllByRole('option')
        expect(options[1]).toHaveTextContent('Item 1')
        expect(options[2]).toHaveTextContent('Item 2')
      })
    })

    describe('when using option groups', () => {
      const groupedItems = [
        {
          children: [
            {id: '11', name: 'Item A1'},
            {id: '12', name: 'Item A2'},
          ],
          id: '1',
          name: 'Group A',
        },
        {
          id: '3',
          name: 'Root Item',
        },
        {
          children: [
            {id: '21', name: 'Item B1'},
            {id: '22', name: 'Item B2'},
          ],
          id: '2',
          name: 'Group B',
        },
      ]

      it('includes an option group for each item with children', async () => {
        const user = userEvent.setup()
        renderContentFilter({items: groupedItems})
        await user.click(screen.getByRole('combobox', {name: 'Example Filter'}))
        const groups = await screen.findAllByRole('group')
        expect(groups).toHaveLength(2)
      })

      it('labels each option group using the related item name', async () => {
        const user = userEvent.setup()
        renderContentFilter({items: groupedItems})
        await user.click(screen.getByRole('combobox', {name: 'Example Filter'}))
        expect(await screen.findByRole('group', {name: 'Group A'})).toBeInTheDocument()
        expect(await screen.findByRole('group', {name: 'Group B'})).toBeInTheDocument()
      })
    })
  })

  describe('selecting an option', () => {
    it('calls onSelect with the item id when selecting an item', async () => {
      const user = userEvent.setup()
      renderContentFilter()
      await user.click(screen.getByRole('combobox', {name: 'Example Filter'}))
      await user.click(await screen.findByRole('option', {name: 'Item 1'}))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('1')
    })

    it('calls onSelect with allItemsId when selecting "All Items"', async () => {
      const user = userEvent.setup()
      renderContentFilter({selectedItemId: '1'})
      await user.click(screen.getByRole('combobox', {name: 'Example Filter'}))
      await user.click(await screen.findByRole('option', {name: 'All Items'}))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('all')
    })
  })

  describe('when disabled', () => {
    it('disables non-selected options', async () => {
      const user = userEvent.setup()
      renderContentFilter({disabled: true})
      const combobox = screen.getByRole('combobox', {name: 'Example Filter'})
      await user.click(combobox)
      const option = await screen.findByRole('option', {name: 'Item 1'})
      expect(option).toHaveAttribute('aria-disabled', 'true')
    })
  })
})
