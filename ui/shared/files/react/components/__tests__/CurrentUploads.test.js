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

import React from 'react'
import {render} from '@testing-library/react'

import CurrentUploads from '../CurrentUploads'
import FileUploader from '../../modules/FileUploader'
import UploadQueue from '../../modules/UploadQueue'

function makeUploader(name) {
  const uploader = new FileUploader({file: new File(['foo'], name, {type: 'text/plain'})})
  return uploader
}

describe('CurrentUploads', () => {
  it('pulls FileUploaders from UploadQueue', () => {
    const {getByText, getAllByRole} = render(<CurrentUploads />)
    const allUploads = [makeUploader('name'), makeUploader('other')]
    UploadQueue.getAllUploaders = jest.fn().mockReturnValue(allUploads)
    UploadQueue.onChange()
    expect(getByText('name')).toBeInTheDocument()
    expect(getByText('other')).toBeInTheDocument()
    expect(getAllByRole('progressbar').length).toEqual(2)
  })

  it('responds to changes in progress', () => {
    const {container} = render(<CurrentUploads />)
    const uploader = makeUploader('name')
    UploadQueue.getAllUploaders = jest.fn().mockReturnValue([uploader])
    UploadQueue.onChange()

    expect(container.querySelector('[aria-valuenow="0"]')).toBeInTheDocument()

    uploader.trackProgress({loaded: 50, total: 100})
    UploadQueue.onChange()

    expect(container.querySelector('[aria-valuenow="50"]')).toBeInTheDocument()
  })
})
