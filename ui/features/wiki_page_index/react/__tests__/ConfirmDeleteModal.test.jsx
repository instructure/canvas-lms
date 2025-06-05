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

import '@instructure/canvas-theme'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import ConfirmDeleteModal from '../ConfirmDeleteModal'

const defaultProps = () => ({
  pageTitles: ['page_1'],
  onConfirm: () => Promise.resolve({failures: []}),
})

test('renders cancel and delete button', () => {
  const ref = React.createRef()
  const {getByText} = render(<ConfirmDeleteModal {...defaultProps()} ref={ref} />)
  ref.current.show()

  expect(getByText('Cancel')).toBeInTheDocument()
  expect(getByText('Delete')).toBeInTheDocument()
})

test('closes the ConfirmDeleteModal when cancel pressed', async () => {
  const ref = React.createRef()
  const onHide = jest.fn()
  const {getByText} = render(<ConfirmDeleteModal {...defaultProps()} onHide={onHide} ref={ref} />)
  ref.current.show()

  const cancelButton = getByText('Cancel')
  fireEvent.click(cancelButton)

  await new Promise(resolve => setTimeout(resolve, 0))
  expect(onHide).toHaveBeenCalledWith(false, false)
})

test('shows spinner on delete', () => {
  const ref = React.createRef()
  const {getByText, getByTitle} = render(<ConfirmDeleteModal {...defaultProps()} ref={ref} />)
  ref.current.show()

  const deleteButton = getByText('Delete')
  fireEvent.click(deleteButton)

  expect(getByTitle('Delete in progress')).toBeInTheDocument()
})

test('renders provided page titles', () => {
  const ref = React.createRef()
  const {getByText} = render(<ConfirmDeleteModal {...defaultProps()} ref={ref} />)
  ref.current.show()

  expect(getByText('page_1')).toBeInTheDocument()
  expect(getByText('1 page selected for deletion')).toBeInTheDocument()
})
