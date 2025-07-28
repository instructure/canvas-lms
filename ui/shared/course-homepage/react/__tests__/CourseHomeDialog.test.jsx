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

import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import createStore from '@canvas/backbone/createStore'
import CourseHomeDialog from '../Dialog'
import axios from '@canvas/axios'

jest.mock('@canvas/axios')

const store = createStore({
  selectedDefaultView: 'modules',
  savedDefaultView: 'modules',
})

const getDefaultProps = () => ({
  store,
  onRequestClose: () => {},
  wikiUrl: 'example.com',
  courseId: '1',
  open: true,
  isPublishing: false,
})

describe('CourseHomeDialog', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    store.setState({
      selectedDefaultView: 'modules',
      savedDefaultView: 'modules',
    })
  })

  test('Renders', () => {
    const {getByText} = render(<CourseHomeDialog {...getDefaultProps()} />)
    expect(getByText('Choose Course Home Page')).toBeInTheDocument()
  })

  test('enables wiki selection if front page is provided', () => {
    const {rerender, getByLabelText} = render(<CourseHomeDialog {...getDefaultProps()} />)
    const wikiRadio = getByLabelText(/Pages Front Page/)
    expect(wikiRadio).toBeDisabled()

    rerender(<CourseHomeDialog {...getDefaultProps()} wikiFrontPageTitle="Welcome" />)
    expect(getByLabelText(/Pages Front Page/)).not.toBeDisabled()
  })

  test('Saves the preference on submit', async () => {
    const onSubmit = jest.fn()
    axios.put.mockResolvedValue({data: {default_view: 'assignments'}})

    const {getByRole, getByLabelText} = render(
      <CourseHomeDialog {...getDefaultProps()} onSubmit={onSubmit} />,
    )

    const assignmentsRadio = getByLabelText('Assignments List')
    fireEvent.click(assignmentsRadio)

    const saveButton = getByRole('button', {name: 'Save'})
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(axios.put).toHaveBeenCalledWith('/api/v1/courses/1', {
        course: {default_view: 'assignments'},
      })
      expect(onSubmit).toHaveBeenCalled()
    })
  })

  test('calls onRequestClose when cancel is clicked', () => {
    const onRequestClose = jest.fn()
    const {getByText} = render(
      <CourseHomeDialog {...getDefaultProps()} onRequestClose={onRequestClose} />,
    )
    const cancelBtn = getByText('Cancel')
    fireEvent.click(cancelBtn)
    expect(onRequestClose).toHaveBeenCalled()
  })

  test('save button disabled when publishing if modules selected', () => {
    const {rerender, getByRole, getByLabelText} = render(
      <CourseHomeDialog {...getDefaultProps()} isPublishing={true} />,
    )
    expect(getByRole('button', {name: 'Choose and Publish'})).toBeDisabled()

    const feedRadio = getByLabelText('Course Activity Stream')
    fireEvent.click(feedRadio)

    rerender(<CourseHomeDialog {...getDefaultProps()} isPublishing={true} />)
    expect(getByRole('button', {name: 'Choose and Publish'})).not.toBeDisabled()
  })
})
