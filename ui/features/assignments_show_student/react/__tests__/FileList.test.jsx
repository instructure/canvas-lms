/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {render} from '@testing-library/react'

import FileList from '../FileList'

describe('FileList', () => {
  const files = [
    new File(['foo'], 'awesome-test-image.png', {type: 'image/png'}),
    new File(['foo'], 'awesome-test-file.pdf', {type: 'application/pdf'}),
  ]
  files.forEach((file, i) => {
    file.id = i
    if (i === 0) {
      file.embedded_iframe_url = 'some_iframe_url'
    }
  })

  it('renders an img tag if an image file is provided', () => {
    const {container} = render(
      <MockedProvider>
        <FileList canRemove={false} files={files.slice(0, 1)} />
      </MockedProvider>
    )
    expect(container.querySelector('svg[name="IconPdf"]')).toBeNull()
    expect(container.querySelector(`img[alt="${files[0].name} preview"]`)).toBeInTheDocument()
  })

  it('renders an icon if a non-image file is provided', () => {
    const {container} = render(
      <MockedProvider>
        <FileList canRemove={false} files={files.slice(1, 2)} />
      </MockedProvider>
    )
    expect(container.querySelector('svg[name="IconPdf"]')).toBeInTheDocument()
    expect(container.querySelector(`img[alt="${files[1].name} preview"]`)).toBeNull()
  })

  it('renders a trash-can icon if able to remove files', () => {
    const {container} = render(
      <MockedProvider>
        <FileList canRemove={true} files={files.slice(0, 1)} removeFileHandler={jest.fn()} />
      </MockedProvider>
    )
    expect(container.querySelector('svg[name="IconTrash"]')).toBeInTheDocument()
  })

  it('does not render a trash can icon if unable to remove files', () => {
    const {container} = render(
      <MockedProvider>
        <FileList canRemove={false} files={files.slice(0, 1)} />
      </MockedProvider>
    )
    expect(container.querySelector('svg[name="IconTrash"]')).toBeNull()
  })

  it('renders a preview if there is a URL to link to', () => {
    const {container} = render(
      <MockedProvider>
        <FileList canRemove={false} files={files.slice(0, 1)} />
      </MockedProvider>
    )
    expect(container.querySelector('a')).toBeInTheDocument()
  })

  it('does not render a preview if there is not a URL to link to', () => {
    const {container} = render(
      <MockedProvider>
        <FileList canRemove={false} files={files.slice(1, 2)} />
      </MockedProvider>
    )
    expect(container.querySelector('a')).not.toBeInTheDocument()
  })
})
