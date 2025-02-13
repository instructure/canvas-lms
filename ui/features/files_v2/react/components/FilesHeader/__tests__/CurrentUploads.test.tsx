/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import CurrentUploads from '../CurrentUploads'
import FileUploader from '@canvas/files/react/modules/FileUploader'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'

function makeUploader(name: string) {
  return new FileUploader({file: new File(['foo'], name, {type: 'text/plain'})})
}

jest.mock('@canvas/files/react/modules/UploadQueue', () => ({
  addChangeListener: jest.fn().mockImplementation(callback => callback()),
  removeChangeListener: jest.fn(),
  getAllUploaders: jest.fn().mockImplementation(() => [makeUploader('foo.txt')]),
}))

describe('CurrentUploads', () => {
  it('renders', () => {
    render(<CurrentUploads />)
    expect(screen.getByTestId('current-uploads')).toBeInTheDocument()
  })

  it("doesn't render", () => {
    UploadQueue.getAllUploaders = jest.fn().mockImplementation(() => [])
    render(<CurrentUploads />)
    expect(screen.queryByTestId('current-uploads')).not.toBeInTheDocument()
  })
})
