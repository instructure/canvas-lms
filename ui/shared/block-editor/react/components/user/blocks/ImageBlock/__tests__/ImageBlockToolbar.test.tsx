/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useNode} from '@craftjs/core'
import {ImageBlock, type ImageBlockProps} from '..'
import {ImageBlockToolbar} from '../ImageBlockToolbar'
import {RCSPropsContext} from '@canvas/block-editor/react/Contexts'

// TODO: Better way to mock RCS data, see AddImageModal.test.tsx
const files = [
  {
    id: 722,
    filename: 'grid.png',
    thumbnail_url:
      'http://canvas.docker/images/thumbnails/722/E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b',
    display_name: 'image_one.png',
    href: 'http://canvas.docker/courses/21/files/722?wrap=1',
    download_url: 'http://canvas.docker/files/722/download?download_frd=1',
    content_type: 'image/png',
    published: true,
    hidden_to_user: true,
    locked_for_user: false,
    unlock_at: null,
    lock_at: null,
    date: '2021-11-03T19:21:27Z',
    uuid: 'E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b',
  },
  {
    id: 716,
    filename: '1635371359_565__0266554465.jpeg',
    thumbnail_url:
      'http://canvas.docker/images/thumbnails/716/9zLFcMIFlNPVtkTHulDGRS1bhiBg8hsL0ms6VeMt',
    display_name: 'image_two.jpg',
    href: 'http://canvas.docker/courses/21/files/716?wrap=1',
    download_url: 'http://canvas.docker/files/716/download?download_frd=1',
    content_type: 'image/jpeg',
    published: true,
    hidden_to_user: false,
    locked_for_user: false,
    unlock_at: null,
    lock_at: null,
    date: '2021-10-27T21:49:19Z',
    uuid: '9zLFcMIFlNPVtkTHulDGRS1bhiBg8hsL0ms6VeMt',
  },
  {
    id: 715,
    filename: '1635371358_548__h3zmqPb-6dw.jpg',
    thumbnail_url:
      'http://canvas.docker/images/thumbnails/715/rIlrdxCJ1h5Ff18Y4C6KJf7HIvCDn5ZAbtnVpNcw',
    display_name: 'image_three.jpg',
    href: 'http://canvas.docker/courses/21/files/715?wrap=1',
    download_url: 'http://canvas.docker/files/715/download?download_frd=1',
    content_type: 'image/jpeg',
    published: true,
    hidden_to_user: false,
    locked_for_user: false,
    unlock_at: null,
    lock_at: null,
    date: '2021-10-27T21:49:18Z',
    uuid: 'rIlrdxCJ1h5Ff18Y4C6KJf7HIvCDn5ZAbtnVpNcw',
  },
]
const imageData = {
  hasMore: false,
  isLoading: false,
  error: '',
  files,
}
const mockTrayProps = {
  canvasOrigin: 'http://some.origin',
  canUploadFiles: true,
  containingContext: {
    contextType: 'course',
    contextId: 'containingContextId',
    userId: 'containingUserId',
  },
  contextType: 'course',
  contextId: 'contextId',
  filesTabDisabled: false,
  host: 'http://example.com',
  jwt: 'JWT',
  refreshToken: () => {},
  themeUrl: 'http://example.com/theme',
  source: {
    initializeCollection() {},
    initializeUpload() {},
    initializeFlickr() {},
    initializeImages() {},
    initializeDocuments() {},
    initializeMedia() {},
    fetchImages: jest.fn().mockResolvedValue({files}),
  },
  storeProps: {},
  images: {
    user: imageData,
    course: imageData,
    group: imageData,
  },
}

const user = userEvent.setup()

let props: Partial<ImageBlockProps>

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(_node => {
      return {
        props,
        actions: {setProp: mockSetProp},
        node: {
          dom: document.createElement('img'),
        },
        domnode: document.createElement('img'),
      }
    }),
  }
})

describe('ImageBlockToolbar', () => {
  beforeEach(() => {
    props = {...(ImageBlock.craft.defaultProps as Partial<ImageBlockProps>)}
  })

  it('should render', () => {
    const {getByText} = render(<ImageBlockToolbar />)

    expect(getByText('Upload Image')).toBeInTheDocument()
    expect(getByText('Constraint')).toBeInTheDocument()
    expect(getByText('Image Size')).toBeInTheDocument()
  })

  it('checks the right constraint', async () => {
    const {getByText} = render(<ImageBlockToolbar />)

    const btn = getByText('Constraint').closest('button') as HTMLButtonElement
    await user.click(btn)

    const coverMenuItem = screen.getByText('Cover')
    const containMenuItem = screen.getByText('Contain')
    const aspectRatioMenuItem = screen.getByText('Match Aspect Ratio')

    expect(coverMenuItem).toBeInTheDocument()
    expect(containMenuItem).toBeInTheDocument()
    expect(aspectRatioMenuItem).toBeInTheDocument()

    const li = coverMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it('changes the constraint prop', async () => {
    const {getByText} = render(<ImageBlockToolbar />)

    const btn = getByText('Constraint').closest('button') as HTMLButtonElement
    await user.click(btn)

    const containMenuItem = screen.getByText('Contain')
    await user.click(containMenuItem)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.constraint).toBe('contain')
    expect(props.maintainAspectRatio).toBe(false)
  })

  it('changes the maintainAspectRatio prop', async () => {
    props.maintainAspectRatio = false
    const {getByText} = render(<ImageBlockToolbar />)

    const btn = getByText('Constraint').closest('button') as HTMLButtonElement
    await user.click(btn)

    const coverMenuItem = screen.getByText('Cover')
    let li = coverMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()

    const aspectRatioMenuItem = screen.getByText('Match Aspect Ratio')
    li = aspectRatioMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).not.toBeInTheDocument()

    await user.click(aspectRatioMenuItem)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.maintainAspectRatio).toBe(true)
    expect(props.constraint).toBe('cover')
  })

  it('changes the image size prop', async () => {
    props.width = 117
    props.height = 217
    const {getByText} = render(<ImageBlockToolbar />)

    const btn = getByText('Image Size').closest('button') as HTMLButtonElement
    await user.click(btn)

    expect(screen.getByText('Auto')).toBeInTheDocument()
    expect(screen.getByText('Fixed size')).toBeInTheDocument()
    expect(screen.getByText('Percent size')).toBeInTheDocument()
    expect(
      screen.getByText('Auto').closest('li')?.querySelector('svg[name="IconCheck"')
    ).toBeInTheDocument()

    await user.click(screen.getByText('Fixed size'))
    expect(props.sizeVariant).toBe('pixel')
  })

  it('can add an image from the AddImageModal', async () => {
    const {getByText, getByRole} = render(
      <RCSPropsContext.Provider value={mockTrayProps}>
        <ImageBlockToolbar />
      </RCSPropsContext.Provider>
    )
    await user.click(getByText(/upload image/i).closest('button') as HTMLButtonElement)
    await user.click(getByRole('tab', {name: /course images/i}))
    await user.click(screen.getByRole('img', {name: /image_one\.png/i}))
    await user.click(screen.getByText(/submit/i).closest('button') as HTMLButtonElement)
    await waitFor(() => {
      expect(props.src).toBe('http://canvas.docker/courses/21/files/722?wrap=1')
    })
  })
})
