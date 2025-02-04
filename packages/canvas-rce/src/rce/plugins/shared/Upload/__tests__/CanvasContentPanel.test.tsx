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
import {render, screen, fireEvent, waitFor, act} from '@testing-library/react'
import CanvasContentPanel from '../CanvasContentPanel'

let files: any[]
let mockContent: any
jest.mock('../../StoreContext', () => {
  return {
    useStoreProps: () => mockContent,
  }
})

describe('CanvasContentPanel', () => {
  const mockTrayProps = {
    canUploadFiles: true,
    contextId: '2',
    contextType: 'course',
    containingContext: {
      contextType: 'user',
      contextId: '1',
      userId: '3',
    },
    filesTabDisabled: false,
    host: 'host',
    jwt: 'jwt',
    refreshToken: jest.fn(),
    source: {
      fetchImages: jest.fn(),
    },
    themeUrl: 'themeUrl',
  }

  const mockSetFileUrl = jest.fn()
  const defaultPlugin = 'user_documents'

  beforeEach(() => {
    jest.clearAllMocks()
    files = [
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

    mockContent = {
      images: {
        Course: {
          files,
          bookmark: 'bookmark',
          isLoading: false,
          hasMore: false,
        },
      },
      contextType: 'Course',
      fetchInitialImages: jest.fn(),
      fetchNextImages: jest.fn(),
      onChangeContext: jest.fn(),
      onChangeSearchString: jest.fn(),
      onChangeSortBy: jest.fn(),
    }
  })

  const renderComponent = (overrideProps: any = {}) => {
    return render(
      <CanvasContentPanel
        trayProps={mockTrayProps}
        canvasOrigin="canvasOrigin"
        plugin={defaultPlugin}
        setFileUrl={mockSetFileUrl}
        {...overrideProps}
      />,
    )
  }

  const waitForLoading = async () => {
    await waitFor(
      () => {
        expect(screen.queryByText('Loading')).not.toBeInTheDocument()
      },
      {timeout: 3000},
    )
  }

  describe('when used to load course_images', () => {
    const plugin = 'course_images'

    it('should update context on load', async () => {
      await act(async () => {
        renderComponent({plugin})
      })

      await waitForLoading()

      await waitFor(() => {
        expect(mockContent.onChangeContext).toHaveBeenCalledWith({
          contextType: 'course',
          contextId: '1',
        })
      })
    })

    it('should render initial images', async () => {
      renderComponent({plugin})
      await waitForLoading()
      await waitFor(() => {
        expect(screen.getByText('image_one.png')).toBeInTheDocument()
      })
    })

    it('returns image url on click', async () => {
      renderComponent({plugin})
      await waitForLoading()
      fireEvent.click(screen.getByText('image_one.png'))
      await waitFor(() => {
        expect(mockSetFileUrl).toHaveBeenCalledWith(
          'http://canvas.docker/courses/21/files/722?wrap=1',
        )
      })
    })

    it('handles no results', async () => {
      mockContent.images.Course.files = []
      renderComponent({plugin})
      await waitForLoading()
      await waitFor(() => {
        expect(screen.getByText('No results.')).toBeInTheDocument()
      })
    })

    it('can load more images', async () => {
      mockContent.images.Course.hasMore = true
      renderComponent({plugin})
      await waitForLoading()
      fireEvent.click(screen.getByText('Load More'))
      await waitFor(() => {
        expect(mockContent.fetchNextImages).toHaveBeenCalled()
      })
    })

    it('searches for images', async () => {
      renderComponent({plugin})
      await waitForLoading()
      fireEvent.change(screen.getByPlaceholderText('Search'), {target: {value: 'image_one'}})
      fireEvent.keyDown(screen.getByPlaceholderText('Search'), {key: 'Enter', code: 'Enter'})
      await waitFor(() => {
        expect(mockContent.onChangeSearchString).toHaveBeenCalledWith('image_one')
      })
    })

    it('sorts images', async () => {
      renderComponent({plugin})
      await waitForLoading()
      fireEvent.click(screen.getByRole('combobox', {name: /sort by/i}))
      fireEvent.click(screen.getByText('Alphabetical'))
      await waitFor(() => {
        expect(mockContent.onChangeSortBy).toHaveBeenCalledWith({dir: 'asc', sort: 'alphabetical'})
      })
    })
  })

  describe('when used to load user images', () => {
    const plugin = 'user_images'

    beforeEach(() => {
      mockContent.contextType = 'User'
      mockContent.images.Course = {}
      mockContent.images.User = {
        files,
        bookmark: 'bookmark',
        isLoading: false,
        hasMore: false,
      }
    })

    it('should update context on load', async () => {
      renderComponent({plugin})
      await waitForLoading()
      await waitFor(() => {
        expect(mockContent.onChangeContext).toHaveBeenCalledWith({
          contextType: 'user',
          contextId: '3',
        })
      })
    })

    it('should render initial images', async () => {
      renderComponent({plugin})
      await waitForLoading()
      await waitFor(() => {
        expect(screen.getByText('image_one.png')).toBeInTheDocument()
      })
    })

    it('returns image url on click', async () => {
      renderComponent({plugin})
      await waitForLoading()
      fireEvent.click(screen.getByText('image_one.png'))
      await waitFor(() => {
        expect(mockSetFileUrl).toHaveBeenCalledWith(
          'http://canvas.docker/courses/21/files/722?wrap=1',
        )
      })
    })

    it('handles no results', async () => {
      mockContent.images.User.files = []
      renderComponent({plugin})
      await waitForLoading()
      await waitFor(() => {
        expect(screen.getByText('No results.')).toBeInTheDocument()
      })
    })

    it('can load more images', async () => {
      mockContent.images.User.hasMore = true
      renderComponent({plugin})
      await waitForLoading()
      fireEvent.click(screen.getByText('Load More'))
      await waitFor(() => {
        expect(mockContent.fetchNextImages).toHaveBeenCalled()
      })
    })

    it('searches for images', async () => {
      renderComponent({plugin})
      await waitForLoading()
      fireEvent.change(screen.getByPlaceholderText('Search'), {target: {value: 'image_one'}})
      fireEvent.keyDown(screen.getByPlaceholderText('Search'), {key: 'Enter', code: 'Enter'})
      await waitFor(() => {
        expect(mockContent.onChangeSearchString).toHaveBeenCalledWith('image_one')
      })
    })

    it('sorts images', async () => {
      renderComponent({plugin})
      await waitForLoading()
      fireEvent.click(screen.getByRole('combobox', {name: /sort by/i}))
      fireEvent.click(screen.getByText('Alphabetical'))
      await waitFor(() => {
        expect(mockContent.onChangeSortBy).toHaveBeenCalledWith({dir: 'asc', sort: 'alphabetical'})
      })
    })
  })
})
