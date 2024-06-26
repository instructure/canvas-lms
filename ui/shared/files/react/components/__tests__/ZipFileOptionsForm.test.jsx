/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render, cleanup, fireEvent, screen} from '@testing-library/react'
import ZipFileOptionsForm from '../ZipFileOptionsForm'

describe('ZipFileOptionsForm', () => {
  beforeEach(() => {
    // add #application to document.body
    const app = document.createElement('div')
    app.id = 'application'
    document.body.appendChild(app)
  })

  afterEach(() => {
    cleanup()
    document.getElementById('application').remove()
  })

  test('creates a display message based on fileOptions', () => {
    const props = {
      fileOptions: {file: {name: 'neat_file'}},
      onZipOptionsResolved: jest.fn(),
    }
    render(<ZipFileOptionsForm {...props} />)
    expect(
      screen.getByText(
        /Would you like to expand the contents of "neat_file" into the current folder, or upload the zip file as is?/
      )
    ).toBeInTheDocument()
  })

  test('handleExpandClick expands zip', () => {
    const onZipOptionsResolved = jest.fn()
    const props = {
      fileOptions: {file: 'the_file_obj'},
      onZipOptionsResolved,
    }
    render(<ZipFileOptionsForm {...props} />)
    fireEvent.click(screen.getByText('Upload It'))
    expect(onZipOptionsResolved).toHaveBeenCalledWith({
      file: 'the_file_obj',
      expandZip: false,
    })
  })
})
