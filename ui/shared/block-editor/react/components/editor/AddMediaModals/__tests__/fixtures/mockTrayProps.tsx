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

const files = [
  {
    id: 722,
    filename: 'grid.png',
    thumbnail_url:
      'http://canvas.docker/images/thumbnails/722/E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b',
    display_name: 'image_one.png',
    title: 'image_one.png',
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
    title: 'image_two.jpg',
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
    title: 'image_three.jpg',
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

const data = {
  hasMore: false,
  isLoading: false,
  error: '',
  files,
}

export const mockTrayProps = {
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
    fetchMedia: jest.fn().mockResolvedValue({files}),
    getSession: jest.fn().mockResolvedValue({usageRightsRequired: false}),
  },
  storeProps: {},
  images: {
    user: data,
    course: data,
    group: data,
  },
}
