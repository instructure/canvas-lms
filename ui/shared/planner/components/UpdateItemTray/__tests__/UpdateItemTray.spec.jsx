/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {within, render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {UpdateItemTray_ as UpdateItemTray} from '../index'

jest.useFakeTimers()

const defaultProps = {
  onSavePlannerItem: () => {},
  locale: 'en',
  timeZone: 'Asia/Tokyo',
  onDeletePlannerItem: () => {},
  courses: [],
  noteItem: {},
}

const simpleItem = (opts = {}) => ({
  uniqueId: '1',
  title: '',
  date: moment('2017-04-28T11:00:00Z'),
  ...opts,
})

let ariaLive

beforeAll(() => {
  ariaLive = document.createElement('div')
  ariaLive.id = 'flash_screenreader_holder'
  ariaLive.setAttribute('role', 'alert')
  document.body.appendChild(ariaLive)
})

afterAll(() => {
  if (ariaLive) ariaLive.remove()
})

afterEach(() => {
  jest.restoreAllMocks()
  document.body.innerHTML = ''
})

describe('UpdateItemTray', () => {
  it('renders form with title, date, course and details fields', () => {
    const noteItem = {
      uniqueId: '1',
      title: 'Planner Item',
      date: moment('2017-04-25 01:49:00-0700'),
      context: {id: '1'},
      details: 'You made this item to remind you of something, but you forgot what.',
    }
    const {getByTestId, getByDisplayValue, getByText, getByLabelText} = render(
      <UpdateItemTray
        {...defaultProps}
        noteItem={noteItem}
        courses={[
          {id: '1', longName: 'a course', enrollmentType: 'StudentEnrollment'},
          {id: '2', longName: 'a course I teach', enrollmentType: 'TeacherEnrollment'},
        ]}
      />,
    )

    expect(getByTestId('title')).toHaveValue('Planner Item')
    expect(getByTestId('details')).toHaveValue(
      'You made this item to remind you of something, but you forgot what.',
    )
    expect(getByTestId('save')).toBeInTheDocument()
    expect(getByTestId('delete')).toBeInTheDocument()
    expect(getByLabelText('Date')).toBeInTheDocument()
    expect(getByLabelText('Course')).toBeInTheDocument()
  })

  it('renders Add To Do header when creating a new to do', () => {
    const {getByText} = render(<UpdateItemTray {...defaultProps} />)
    expect(getByText('Add To Do')).toBeInTheDocument()
  })

  it('renders Edit header when editing an existing item', () => {
    const noteItem = {uniqueId: '1', title: 'My Todo Item'}
    const {getByText} = render(<UpdateItemTray {...defaultProps} noteItem={noteItem} />)
    expect(getByText('Edit My Todo Item')).toBeInTheDocument()
  })

  it('allows typing in title input', async () => {
    const user = userEvent.setup({delay: null})
    const {getByTestId} = render(<UpdateItemTray {...defaultProps} />)

    const titleInput = getByTestId('title')
    await user.type(titleInput, 'New Text')
    expect(titleInput).toHaveValue('New Text')
  })

  it('allows typing in details input', async () => {
    const user = userEvent.setup({delay: null})
    const {getByTestId} = render(<UpdateItemTray {...defaultProps} />)

    const detailsInput = getByTestId('details')
    await user.type(detailsInput, 'New Details')
    expect(detailsInput).toHaveValue('New Details')
  })

  it('disables save button when title is empty', () => {
    const item = simpleItem()
    const {getByTestId} = render(<UpdateItemTray {...defaultProps} noteItem={item} />)

    const saveButton = getByTestId('save')
    expect(saveButton).toBeDisabled()
  })

  it('enables save button when title and date are present', () => {
    const item = simpleItem({title: 'an item'})
    const {getByTestId} = render(<UpdateItemTray {...defaultProps} noteItem={item} />)

    const saveButton = getByTestId('save')
    expect(saveButton).toBeEnabled()
  })

  it('shows error message when title is cleared', async () => {
    const user = userEvent.setup({delay: null})
    const {getByTestId, getByText} = render(
      <UpdateItemTray {...defaultProps} noteItem={{uniqueId: '1', title: 'an item'}} />,
    )

    const titleInput = getByTestId('title')
    await user.clear(titleInput)

    expect(getByText('title is required')).toBeInTheDocument()
  })

  it('clears error message when title is entered', async () => {
    const user = userEvent.setup({delay: null})
    const {getByTestId, queryByText} = render(
      <UpdateItemTray {...defaultProps} noteItem={{uniqueId: '1', title: 'an item'}} />,
    )

    const titleInput = getByTestId('title')
    await user.clear(titleInput)
    await user.type(titleInput, 'new title')

    expect(queryByText('title is required')).not.toBeInTheDocument()
  })

  it('sets default datetime to end of day when no date provided', () => {
    const item = {title: 'an item', date: ''}
    const {getByLabelText} = render(<UpdateItemTray {...defaultProps} noteItem={item} />)

    const dateInput = getByLabelText('Date')
    expect(dateInput).toBeInTheDocument()
  })

  it('respects the provided timezone in date display', () => {
    const item = simpleItem({date: moment('2017-04-25 12:00:00-0300')})
    const {getByDisplayValue} = render(<UpdateItemTray {...defaultProps} noteItem={item} />)

    expect(getByDisplayValue('April 26, 2017')).toBeInTheDocument()
  })

  it('does not render delete button for new items', () => {
    const {queryByTestId} = render(<UpdateItemTray {...defaultProps} />)
    expect(queryByTestId('delete')).not.toBeInTheDocument()
  })

  it('renders delete button for existing items', () => {
    const {getByTestId} = render(
      <UpdateItemTray {...defaultProps} noteItem={{uniqueId: '1', title: 'some note'}} />,
    )
    expect(getByTestId('delete')).toBeInTheDocument()
  })

  it('renders only optional course option when no courses provided', async () => {
    const user = userEvent.setup({delay: null})
    const {getByLabelText, getByRole} = render(<UpdateItemTray {...defaultProps} />)

    const courseSelect = getByLabelText('Course')
    await user.click(courseSelect)

    const listbox = getByRole('listbox', {hidden: true})
    const {getAllByRole} = within(listbox)
    const options = getAllByRole('option')

    expect(options).toHaveLength(1)
    expect(options[0]).toHaveTextContent('Optional: Add Course')
  })

  it('renders course options plus optional when courses are provided', async () => {
    const user = userEvent.setup({delay: null})
    const courses = [
      {id: '1', longName: 'first course', enrollmentType: 'StudentEnrollment'},
      {id: '2', longName: 'second course', enrollmentType: 'StudentEnrollment'},
    ]
    const {getByLabelText, getByRole} = render(
      <UpdateItemTray {...defaultProps} courses={courses} />,
    )

    const courseSelect = getByLabelText('Course')
    await user.click(courseSelect)

    const listbox = getByRole('listbox', {hidden: true})
    const {getAllByRole} = within(listbox)
    const options = getAllByRole('option')

    expect(options).toHaveLength(3)
    expect(options[0]).toHaveTextContent('Optional: Add Course')
    expect(options[1]).toHaveTextContent('first course')
    expect(options[2]).toHaveTextContent('second course')
  })

  it('calls save callback with updated data when save button clicked', async () => {
    const saveMock = jest.fn()
    const user = userEvent.setup({delay: null})
    const item = simpleItem({title: 'original title'})

    const {getByTestId} = render(
      <UpdateItemTray {...defaultProps} noteItem={item} onSavePlannerItem={saveMock} />,
    )

    const titleInput = getByTestId('title')
    await user.clear(titleInput)
    await user.type(titleInput, 'new title')

    const saveButton = getByTestId('save')
    await user.click(saveButton)

    expect(saveMock).toHaveBeenCalledWith({
      uniqueId: '1',
      title: 'new title',
      date: item.date.toISOString(),
      context: {id: null},
    })
  })

  it('handles course selection correctly', async () => {
    const saveMock = jest.fn()
    const user = userEvent.setup({delay: null})
    const courses = [{id: '42', longName: 'Test Course', enrollmentType: 'StudentEnrollment'}]
    const item = simpleItem({title: 'test item'})

    const {getByTestId, getByLabelText, getByRole, getByText} = render(
      <UpdateItemTray
        {...defaultProps}
        noteItem={item}
        courses={courses}
        onSavePlannerItem={saveMock}
      />,
    )

    // Select a course
    const courseSelect = getByLabelText('Course')
    await user.click(courseSelect)

    const listbox = getByRole('listbox', {hidden: true})
    const courseOption = within(listbox).getByText('Test Course')
    await user.click(courseOption)

    const saveButton = getByTestId('save')
    await user.click(saveButton)

    expect(saveMock).toHaveBeenCalledWith({
      uniqueId: '1',
      title: 'test item',
      date: item.date.toISOString(),
      context: {id: '42'},
    })
  })

  it('handles setting course to none correctly', async () => {
    const saveMock = jest.fn()
    const user = userEvent.setup({delay: null})
    const courses = [{id: '42', longName: 'Test Course', enrollmentType: 'StudentEnrollment'}]
    const item = simpleItem({title: 'test item', courseId: '42'})

    const {getByTestId, getByLabelText, getByRole} = render(
      <UpdateItemTray
        {...defaultProps}
        noteItem={item}
        courses={courses}
        onSavePlannerItem={saveMock}
      />,
    )

    // Select "none" option
    const courseSelect = getByLabelText('Course')
    await user.click(courseSelect)

    const listbox = getByRole('listbox', {hidden: true})
    const noneOption = within(listbox).getByText('Optional: Add Course')
    await user.click(noneOption)

    const saveButton = getByTestId('save')
    await user.click(saveButton)

    expect(saveMock).toHaveBeenCalledWith({
      uniqueId: '1',
      title: 'test item',
      date: item.date.toISOString(),
      context: {id: null},
    })
  })

  it('calls delete callback when delete button clicked and confirmed', async () => {
    const deleteMock = jest.fn()
    const user = userEvent.setup({delay: null})
    const item = simpleItem({title: 'a title'})

    const confirmSpy = jest.spyOn(window, 'confirm').mockReturnValue(true)

    const {getByTestId} = render(
      <UpdateItemTray {...defaultProps} noteItem={item} onDeletePlannerItem={deleteMock} />,
    )

    const deleteButton = getByTestId('delete')
    await user.click(deleteButton)

    expect(confirmSpy).toHaveBeenCalledWith('Are you sure you want to delete this planner item?')
    expect(deleteMock).toHaveBeenCalledWith(item)

    confirmSpy.mockRestore()
  })

  it('does not call delete callback when delete is cancelled', async () => {
    const deleteMock = jest.fn()
    const user = userEvent.setup({delay: null})
    const item = simpleItem({title: 'a title'})

    const confirmSpy = jest.spyOn(window, 'confirm').mockReturnValue(false)

    const {getByTestId} = render(
      <UpdateItemTray {...defaultProps} noteItem={item} onDeletePlannerItem={deleteMock} />,
    )

    const deleteButton = getByTestId('delete')
    await user.click(deleteButton)

    expect(confirmSpy).toHaveBeenCalled()
    expect(deleteMock).not.toHaveBeenCalled()

    confirmSpy.mockRestore()
  })

  it('updates form when new note item is provided', () => {
    const courses = [
      {id: '1', longName: 'First Course', enrollmentType: 'StudentEnrollment'},
      {id: '2', longName: 'Second Course', enrollmentType: 'StudentEnrollment'},
    ]

    const noteItem1 = {
      uniqueId: '1',
      title: 'First Item',
      context: {id: '1'},
    }

    const {getByTestId, rerender} = render(
      <UpdateItemTray {...defaultProps} noteItem={noteItem1} courses={courses} />,
    )

    expect(getByTestId('title')).toHaveValue('First Item')

    const noteItem2 = {
      uniqueId: '2',
      title: 'Second Item',
      context: {id: '2'},
    }

    rerender(<UpdateItemTray {...defaultProps} noteItem={noteItem2} courses={courses} />)

    expect(getByTestId('title')).toHaveValue('Second Item')
  })

  it('preserves user changes when same note item is provided again', async () => {
    const user = userEvent.setup({delay: null})
    const note = simpleItem({title: 'original title'})

    const {getByTestId, rerender} = render(<UpdateItemTray {...defaultProps} noteItem={note} />)

    const titleInput = getByTestId('title')
    await user.clear(titleInput)
    await user.type(titleInput, 'user changed title')

    expect(titleInput).toHaveValue('user changed title')

    // Rerender with same note object (but new reference)
    rerender(<UpdateItemTray {...defaultProps} noteItem={{...note}} />)

    // User changes should be preserved
    expect(titleInput).toHaveValue('user changed title')
  })
})
