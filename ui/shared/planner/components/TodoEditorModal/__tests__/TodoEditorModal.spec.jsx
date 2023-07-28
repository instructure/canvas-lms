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

import moment from 'moment-timezone'
import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import TodoEditorModal from '../index'
import {initialize} from '../../../utilities/alertUtils'

jest.useFakeTimers()

const defaultProps = (options = {}) => ({
  savePlannerItem: () => {},
  deletePlannerItem: () => {},
  onEdit: () => {},
  onClose: () => {},
  todoItem: null,
  locale: 'en',
  timeZone: 'America/Denver',
  courses: [],
  ...options,
})

const simpleTodoItem = (opts = {}) => ({
  uniqueId: '1',
  title: 'todo',
  date: moment('2021-05-08T11:00:00Z'),
  context: {id: null},
  time: '11:00',
  details: '',
  ...opts,
})

const successFn = jest.fn()
const errorFn = jest.fn()

beforeAll(() => {
  initialize({visualSuccessCallback: successFn, visualErrorCallback: errorFn})
})

it('does not show the editor modal when todoItem is null', () => {
  const {queryByTestId} = render(<TodoEditorModal {...defaultProps()} />)
  expect(queryByTestId('todo-editor-modal')).not.toBeInTheDocument()
})

it('shows the editor modal when todoItem is set', () => {
  const mockOnEdit = jest.fn()
  const {getByTestId} = render(
    <TodoEditorModal {...defaultProps({onEdit: mockOnEdit, todoItem: simpleTodoItem()})} />
  )
  expect(getByTestId('todo-editor-modal')).toBeInTheDocument()
  expect(mockOnEdit).toHaveBeenCalled()
})

it('calls onClose when the x is clicked ', () => {
  const mockOnClose = jest.fn()
  const newProps = {...defaultProps({onClose: mockOnClose, todoItem: simpleTodoItem()})}
  const {getByTestId} = render(<TodoEditorModal {...newProps} />)
  const closeButton = getByTestId('close-editor-modal').querySelector('button')
  fireEvent.click(closeButton)

  expect(mockOnClose).toHaveBeenCalled()
})

it('updates the planner item and then closes the editor when Save is clicked ', async () => {
  const todoItem = simpleTodoItem()
  const mockOnClose = jest.fn()
  const mockSave = jest.fn(() => Promise.resolve())
  const newProps = {
    ...defaultProps({
      onClose: mockOnClose,
      savePlannerItem: mockSave,
      todoItem,
    }),
  }
  const {getByTestId, getByLabelText} = render(<TodoEditorModal {...newProps} />)
  const title = getByTestId('title')
  const date = getByLabelText('Date')
  const details = getByTestId('details')

  fireEvent.change(date, {target: {value: 'May 30,2021'}})
  fireEvent.blur(date)
  fireEvent.change(title, {target: {value: 'Updated Todo'}})
  fireEvent.change(details, {target: {value: 'These are the todo details'}})
  jest.runOnlyPendingTimers()

  const saveButton = getByTestId('save')
  fireEvent.click(saveButton)

  expect(mockSave).toHaveBeenCalledWith({
    ...todoItem,
    title: 'Updated Todo',
    date: moment('2021-05-30T11:00:00Z').toISOString(),
    details: 'These are the todo details',
  })

  await waitFor(() => {
    expect(mockOnClose).toHaveBeenCalled()
  })
})

it('deletes the planner item and then closes the editor when Delete is clicked ', async () => {
  const todoItem = simpleTodoItem()
  const confirmSpy = jest.spyOn(window, 'confirm').mockReturnValue(true)
  const mockOnClose = jest.fn()
  const mockDelete = jest.fn(() => Promise.resolve())
  const newProps = {
    ...defaultProps({
      onClose: mockOnClose,
      deletePlannerItem: mockDelete,
      todoItem,
    }),
  }
  const {getByTestId} = render(<TodoEditorModal {...newProps} />)
  const deleteButton = getByTestId('delete')
  fireEvent.click(deleteButton)

  expect(confirmSpy).toHaveBeenCalled()
  expect(mockDelete).toHaveBeenCalledWith(todoItem)
  await waitFor(() => {
    expect(mockOnClose).toHaveBeenCalled()
  })
})

it('shows an error if To-do update fails', async () => {
  const todoItem = simpleTodoItem()
  const mockSave = jest.fn(() => Promise.reject())
  const newProps = {
    ...defaultProps({
      savePlannerItem: mockSave,
      todoItem,
    }),
  }
  const {getByTestId} = render(<TodoEditorModal {...newProps} />)
  const saveButton = getByTestId('save')
  fireEvent.click(saveButton)

  await waitFor(() => expect(errorFn).toHaveBeenCalledWith('Failed saving changes on todo.'))
})

it('shows an error if To-do deletion fails', async () => {
  const todoItem = simpleTodoItem()
  jest.spyOn(window, 'confirm').mockReturnValue(true)
  const mockDelete = jest.fn(() => Promise.reject())
  const newProps = {
    ...defaultProps({
      deletePlannerItem: mockDelete,
      todoItem,
    }),
  }
  const {getByTestId} = render(<TodoEditorModal {...newProps} />)
  const deleteButton = getByTestId('delete')
  fireEvent.click(deleteButton)

  await waitFor(() => expect(errorFn).toHaveBeenCalledWith('Failed to delete todo.'))
})
