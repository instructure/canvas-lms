/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import CourseImagePicker from '../CourseImagePicker'
import fakeENV from '@canvas/test-utils/fakeENV'
import $ from 'jquery'

describe('CourseImagePicker Component', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = fakeENV.setup({
      COURSE_IMAGES_ENABLED: true,
      FEATURES: {
        course_images: true,
      },
    })

    // Mock jQuery's flashError function to prevent the test from failing
    $.flashError = jest.fn()
  })

  afterEach(() => {
    fakeENV.teardown(oldEnv)

    // Clean up jQuery mocks
    jest.restoreAllMocks()
  })

  const renderComponent = (props = {}) => {
    return render(<CourseImagePicker courseId="101" handleFileUpload={jest.fn()} {...props} />)
  }

  it('calls the handleFileUpload prop when an image is selected', async () => {
    const handleFileUpload = jest.fn()
    const {getByTestId} = renderComponent({handleFileUpload})

    const file = new File(['test image'], 'image.jpg', {type: 'image/jpeg'})
    const dropZone = getByTestId('course-image-drop-zone')
    await userEvent.upload(dropZone, file)

    expect(handleFileUpload).toHaveBeenCalledWith(
      expect.objectContaining({
        dataTransfer: {
          files: [file],
        },
        preventDefault: expect.any(Function),
        stopPropagagtion: expect.any(Function),
      }),
      '101',
    )
  })

  it('shows an error message when a non-image file is dropped', async () => {
    const handleFileUpload = jest.fn()
    const {getByTestId, findByText} = renderComponent({handleFileUpload})

    const file = new File(['test file'], 'test.txt', {type: 'text/plain'})
    const dropZone = getByTestId('course-image-drop-zone')

    // Trigger file drop rejection by simulating the change event
    fireEvent.change(dropZone, {
      target: {
        files: [file],
      },
    })

    // The FileDrop component will show the error message
    const errorMessage = await findByText('File must be an image')
    expect(errorMessage).toBeInTheDocument()
    expect(handleFileUpload).not.toHaveBeenCalled()
  })

  it('shows a loading spinner when uploading', () => {
    const {getByText} = renderComponent({uploadingImage: true})
    expect(getByText('Loading')).toBeInTheDocument()
  })
})
