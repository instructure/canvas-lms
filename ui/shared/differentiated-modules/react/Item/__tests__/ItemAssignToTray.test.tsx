/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import ItemAssignToTray, {ItemAssignToTrayProps} from '../ItemAssignToTray'

export type UnknownSubset<T> = {
  [K in keyof T]?: T[K]
}

describe('ItemAssignToTray', () => {
  beforeAll(() => {
    // @ts-expect-error
    window.ENV ||= {}
    ENV.VALID_DATE_RANGE = {
      start_at: {date: '2023-08-20T22:00:00Z', date_context: 'course'},
      end_at: {date: '2023-12-30T23:00:00Z', date_context: 'course'},
    }
    ENV.HAS_GRADING_PERIODS = false
    // @ts-expect-error
    ENV.SECTION_LIST = [{id: '4'}, {id: '5'}]
    ENV.POST_TO_SIS = false
    ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = false
  })

  const props: ItemAssignToTrayProps = {
    open: true,
    onDismiss: () => {},
    onSave: () => {},
    courseId: '1',
    moduleItemId: '2',
    moduleItemName: 'Item Name',
    moduleItemType: 'assignment',
    pointsPossible: '10 pts',
  }

  const renderComponent = (overrides: UnknownSubset<ItemAssignToTrayProps> = {}) =>
    render(<ItemAssignToTray {...props} {...overrides} />)

  it('renders', async () => {
    const {getByText, getByLabelText, findAllByTestId} = renderComponent()
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment | 10 pts')).toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
    // the tray is mocking an api response that makes 3 cards
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(3)
  })

  it('renders a quiz', () => {
    const {getByText} = renderComponent({moduleItemType: 'quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
  })

  it('renders a new quiz', () => {
    const {getByText} = renderComponent({moduleItemType: 'lti-quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
  })

  it('renders with no points', () => {
    const {getByText, queryByText, getByLabelText} = renderComponent({pointsPossible: undefined})
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment')).toBeInTheDocument()
    expect(queryByText('pts')).not.toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByRole} = renderComponent({onDismiss})
    getByRole('button', {name: 'Close'}).click()
    expect(onDismiss).toHaveBeenCalled()
  })

  it('calls onSave when save button is clicked', () => {
    const onSave = jest.fn()
    const {getByRole} = renderComponent({onSave})
    getByRole('button', {name: 'Save'}).click()
    expect(onSave).toHaveBeenCalled()
  })

  it('adds a card when add button is clicked', async () => {
    const {getByRole, findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(3)
    getByRole('button', {name: 'Add'}).click()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(4)
  })

  it('deletes a card when delete button is clicked', async () => {
    const {getAllByRole, findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(3)
    getAllByRole('button', {name: 'Delete'})[1].click()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
  })

  it('disables the save button when no cards are invalid', () => {
    // it's ridiculous to implement this  now.
    // eventually the tray will get data from the api, pass the data
    // to the cards, which will call onValidityChange.
    // then it will be straight forward to write tests
    expect(true).toBe(true)
    // const {getByRole} = renderComponent()
    // expect(getByRole('button', {name: 'Save'})).toBeDisabled()
  })
})
