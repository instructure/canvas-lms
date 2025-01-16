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
import {render} from '@testing-library/react'
import File from '../../../backbone/models/File'
import DialogPreview from '../DialogPreview'
import FilesystemObjectThumbnail from '../FilesystemObjectThumbnail'

describe('DialogPreview', () => {
  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('renders a single item with FilesystemObjectThumbnail', () => {
    const file = new File({name: 'Test File', thumbnail_url: 'blah'})
    file.url = () => 'some_url'
    jest
      .spyOn(FilesystemObjectThumbnail.prototype, 'render')
      .mockReturnValue(<div data-testid="mock-thumbnail" />)

    const {getByTestId} = render(<DialogPreview itemsToShow={[file]} />)

    expect(getByTestId('dialog-preview-container')).toBeInTheDocument()
    expect(getByTestId('mock-thumbnail')).toBeInTheDocument()
  })

  it('renders multiple file items with icons', () => {
    const url = () => 'some_url'
    const file1 = new File({name: 'Test File 1', thumbnail_url: 'blah'})
    const file2 = new File({name: 'Test File 2', thumbnail_url: 'blah'})
    file1.url = url
    file2.url = url

    const {getByTestId} = render(<DialogPreview itemsToShow={[file1, file2]} />)

    expect(getByTestId('multi-thumbnail-0')).toBeInTheDocument()
    expect(getByTestId('multi-thumbnail-1')).toBeInTheDocument()
  })
})
