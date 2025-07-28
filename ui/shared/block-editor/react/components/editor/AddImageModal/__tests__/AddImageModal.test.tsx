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
import {render, fireEvent, waitFor, screen} from '@testing-library/react'
import {AddImageModal} from '../AddImageModal'
import {RCSPropsContext} from '../../../../Contexts'
import userEvent from '@testing-library/user-event'

// TODO: Better way to mock RCS data, see ImageBlockToolbar.test.tsx
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
let mockTrayProps: any
const user = userEvent.setup()

describe('AddImageModal', () => {
  const mockOnSubmit = jest.fn()
  const mockOnDismiss = jest.fn()

  const imageData = {
    hasMore: false,
    isLoading: false,
    error: '',
    files,
  }

  const defaultProps = {
    open: true,
    onSubmit: mockOnSubmit,
    onDismiss: mockOnDismiss,
    accept: 'image/*',
  }

  beforeEach(() => {
    jest.clearAllMocks()

    mockTrayProps = {
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
        getSession: jest.fn().mockResolvedValue({usageRightsRequired: false}),
      },
      storeProps: {},
      images: {
        user: imageData,
        course: imageData,
        group: imageData,
      },
    }
  })

  const renderComponent = (props = {}) => {
    return render(
      <RCSPropsContext.Provider value={mockTrayProps}>
        <AddImageModal {...defaultProps} {...props} />
      </RCSPropsContext.Provider>,
    )
  }

  it('renders with 4 tabs', () => {
    const {getByRole, getByText} = renderComponent()
    expect(getByRole('heading', { name: 'Upload Image' })).toBeInTheDocument()
    expect(getByText('Computer')).toBeInTheDocument()
    expect(getByText('URL')).toBeInTheDocument()
    expect(getByText('Course Images')).toBeInTheDocument()
    expect(getByText('User Images')).toBeInTheDocument()
  })

  it('calls onDismiss when the modal is dismissed', async () => {
    renderComponent()
    await user.click(screen.getAllByText('Close')[1].closest('button') as Element)
    waitFor(() => {
      expect(mockOnDismiss).toHaveBeenCalled()
    })
  })

  it('can submit URL images', async () => {
    renderComponent()
    await user.click(screen.getByText('URL'))
    await waitFor(() => {
      expect(screen.getByText('File URL')).toBeInTheDocument()
    })
    await user.type(
      screen.getByRole('textbox', {name: /file url/i}),
      'http://example.com/image.jpg',
    )
    // @ts-expect-error
    await user.click(screen.getByText('Submit').closest('button'))
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith('http://example.com/image.jpg', '')
    })
  }, 10000)

  it('can submit URL images with alt texts', async () => {
    renderComponent()
    await user.click(screen.getByText('URL'))
    await waitFor(() => {
      expect(screen.getByText('File URL')).toBeInTheDocument()
    })
    await user.type(
      screen.getByRole('textbox', {name: /file url/i}),
      'http://example.com/image.jpg',
    )

    fireEvent.change(
      (await screen.getByPlaceholderText('(Describe the image)')) as unknown as HTMLInputElement,
      {target: {value: 'Some alt text'}},
    )

    // @ts-expect-error
    await user.click(screen.getByText('Submit').closest('button'))
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith('http://example.com/image.jpg', 'Some alt text')
    })
  }, 10000)

  it.skip('can submit course images', async () => {
    // RCX-2420 to fix it
    renderComponent()
    await user.click(screen.getByText('Course Images'))
    await waitFor(() => {
      expect(screen.getByPlaceholderText('Search')).toBeInTheDocument()
    })
    await user.click(screen.getByRole('img', {name: /image_one\.png/i}))
    await user.click(screen.getByRole('button', {name: /submit/i}))
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith(
        'http://canvas.docker/courses/21/files/722?wrap=1',
        '',
      )
    })
  })

  it.skip('can submit user images', async () => {
    // RCX-2340 to fix it
    mockTrayProps.containingContext.contextType = 'user'
    renderComponent()
    await user.click(screen.getByText('User Images'))
    await waitFor(() => {
      expect(screen.getByPlaceholderText('Search')).toBeInTheDocument()
    })
    await user.click(screen.getByRole('img', {name: /image_one\.png/i}))
    await user.click(screen.getByRole('button', {name: /submit/i}))
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith(
        'http://canvas.docker/courses/21/files/722?wrap=1',
        '',
      )
    })
  })

  // submitting an image requires too much mocking of the RCS to be a good test
  it('can upload images', async () => {
    const aFile = new File(['foo'], 'foo.png', {
      type: 'image/png',
    })
    renderComponent()

    fireEvent.change(await screen.findByTestId('filedrop'), {
      target: {
        files: [aFile],
      },
    })
    expect(screen.getByText(/clear selected file: foo\.png/i)).toBeInTheDocument()
  })
})
