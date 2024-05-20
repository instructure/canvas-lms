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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {ManageUserLabels} from '../ManageUserLabels'

const createProps = overrides => {
  return {
    open: true,
    labels: ['Assignment Info', 'Important'],
    onCreate: jest.fn(),
    onDelete: jest.fn(),
    onClose: jest.fn(),
    ...overrides,
  }
}

describe('ManageUserLabels', () => {
  it('renders', () => {
    const {container} = render(<ManageUserLabels {...createProps()} />)

    expect(container).toBeInTheDocument()
  })

  it('renders the correct number of labels', () => {
    const {getAllByTestId} = render(<ManageUserLabels {...createProps()} />)

    expect(getAllByTestId('label')).toHaveLength(2)
  })

  it('correctly adds labels', () => {
    const props = createProps()
    const {getByLabelText, getByTestId, getAllByTestId, getByText} = render(
      <ManageUserLabels {...props} />
    )

    fireEvent.change(getByLabelText('Label Name'), {target: {value: 'New Label'}})
    fireEvent.click(getByTestId('add-label'))

    expect(getAllByTestId('label')).toHaveLength(3)
    expect(getByText('New Label')).toBeInTheDocument()
  })

  it('shows error if trying to add a label that already exists', () => {
    const props = createProps()
    const {getByLabelText, getByTestId, getAllByTestId, getByText} = render(
      <ManageUserLabels {...props} />
    )

    fireEvent.change(getByLabelText('Label Name'), {target: {value: 'Important'}})
    fireEvent.click(getByTestId('add-label'))

    expect(getAllByTestId('label')).toHaveLength(2)
    expect(
      getByText('The specified label already exists. Please enter a different label name.')
    ).toBeInTheDocument()
  })

  it('correctly deletes labels', () => {
    const props = createProps()
    const {getAllByTestId} = render(<ManageUserLabels {...props} />)

    fireEvent.click(getAllByTestId('delete-label')[0])

    expect(getAllByTestId('label')).toHaveLength(1)
  })

  it('correctly closes the modal', () => {
    const props = createProps()
    const {getAllByText} = render(<ManageUserLabels {...props} />)

    fireEvent.click(getAllByText('Close')[1])

    expect(props.onClose).toHaveBeenCalled()
  })

  it('calls onCreate when the Save button is clicked', () => {
    const props = createProps()
    const {getByLabelText, getByTestId, getByText} = render(<ManageUserLabels {...props} />)

    fireEvent.change(getByLabelText('Label Name'), {target: {value: 'Test 1'}})
    fireEvent.click(getByTestId('add-label'))

    fireEvent.change(getByLabelText('Label Name'), {target: {value: 'Test 2'}})
    fireEvent.click(getByTestId('add-label'))

    fireEvent.click(getByText('Save'))

    expect(props.onCreate).toHaveBeenCalled()
    expect(props.onCreate).toHaveBeenCalledWith(['Test 1', 'Test 2'])
  })

  it('does not calls onCreate when the Save button is clicked and no labels are added', () => {
    const props = createProps()
    const {getByText} = render(<ManageUserLabels {...props} />)

    fireEvent.click(getByText('Save'))

    expect(props.onCreate).not.toHaveBeenCalled()
  })

  it('calls onDelete when the Save button is clicked', () => {
    const props = createProps()
    const {getAllByTestId, getByText} = render(<ManageUserLabels {...props} />)

    fireEvent.click(getAllByTestId('delete-label')[0])

    fireEvent.click(getByText('Save'))

    waitFor(() => {
      expect(props.onDelete).toHaveBeenCalled()
      expect(props.onDelete).toHaveBeenCalledWith(['Assignment Info'])
    })
  })

  it('does not calls onDelete when the Save button is clicked and no labels are deleted', () => {
    const props = createProps()
    const {getByText} = render(<ManageUserLabels {...props} />)

    fireEvent.click(getByText('Save'))

    expect(props.onDelete).not.toHaveBeenCalled()
  })

  it('does not calls onDelete when the Save button is clicked and unsaved labels are deleted', () => {
    const props = createProps()
    const {getByLabelText, getByTestId, getAllByTestId, getByText} = render(
      <ManageUserLabels {...props} />
    )

    fireEvent.change(getByLabelText('Label Name'), {target: {value: 'Beta'}})
    fireEvent.click(getByTestId('add-label'))
    fireEvent.click(getAllByTestId('delete-label')[1])

    fireEvent.click(getByText('Save'))

    expect(props.onDelete).not.toHaveBeenCalled()
  })

  it('component resets to its initial state when the modal is closed', () => {
    const props = createProps()
    const {getByLabelText, getByTestId, getAllByTestId, getByText, getAllByText} = render(
      <ManageUserLabels {...props} />
    )

    fireEvent.change(getByLabelText('Label Name'), {target: {value: 'New Label'}})
    fireEvent.click(getByTestId('add-label'))

    expect(getAllByTestId('label')).toHaveLength(3)
    expect(getByText('New Label')).toBeInTheDocument()

    fireEvent.click(getAllByText('Close')[1])

    expect(getAllByTestId('label')).toHaveLength(2)
  })
})
