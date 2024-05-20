// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import GroupImportModal from '../GroupImportModal'
import * as apiClient from '../apiClient'

describe('GroupImportModal', () => {
  it('adds an error message when an unsupported filetype is selected', async () => {
    const badFile = new File(['(⌐□_□)'], 'file.png', {type: 'image/png'})
    const {findByText, findByLabelText} = render(
      <GroupImportModal setProgress={jest.fn} groupCategoryId={1} />
    )
    const fileDrop = await findByLabelText(/Upload CSV File/i)

    // Source: https://github.com/testing-library/react-testing-library/issues/93#issuecomment-403887769
    Object.defineProperty(fileDrop, 'files', {
      value: [badFile],
    })

    fireEvent.change(fileDrop)

    expect(await findByText('Invalid file type')).toBeInTheDocument()
  })

  // FOO-4218 - remove or rewrite to remove spies on imports
  it.skip('sends the file to the API on successful upload', async () => {
    const mockCreateImport = jest.spyOn(apiClient, 'createImport').mockImplementation(() => {
      return new Promise(resolve => {
        resolve(true)
      })
    })

    const file = new File(['1,2,3'], 'file.csv', {type: 'text/csv'})
    const {findByLabelText} = render(<GroupImportModal setProgress={jest.fn} groupCategoryId={1} />)
    const fileDrop = await findByLabelText(/Upload CSV File/i)

    // Source: https://github.com/testing-library/react-testing-library/issues/93#issuecomment-403887769
    Object.defineProperty(fileDrop, 'files', {
      value: [file],
    })

    fireEvent.change(fileDrop)

    expect(mockCreateImport).toHaveBeenCalled()
  })

  // FOO-4218 - remove or rewrite to remove spies on imports
  it.skip('displays an error when the API requests fails', async () => {
    jest.spyOn(apiClient, 'createImport').mockImplementation(() => {
      return new Promise((resolve, reject) => {
        reject(new Error("That didn't work"))
      })
    })

    const file = new File(['1,2,3'], 'file.csv', {type: 'text/csv'})
    const {findByLabelText, findAllByText} = render(
      <GroupImportModal setProgress={jest.fn} groupCategoryId={1} />
    )
    const fileDrop = await findByLabelText(/Upload CSV File/i)

    // Source: https://github.com/testing-library/react-testing-library/issues/93#issuecomment-403887769
    Object.defineProperty(fileDrop, 'files', {
      value: [file],
    })

    fireEvent.change(fileDrop)

    const errors = await findAllByText('There was an error uploading your file. Please try again.')
    expect(errors[0]).toBeInTheDocument()
  })
})
