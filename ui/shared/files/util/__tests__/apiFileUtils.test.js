/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {waitFor} from '@testing-library/react'
import {uploadFile} from '../apiFileUtils'

describe('apiFileUtils', () => {
  const server = setupServer()

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  describe('uploadFile', () => {
    it('runs the onSuccess method after upload', async () => {
      const onSuccess = vi.fn()
      const onFail = vi.fn()

      server.use(
        http.post('/api/v1/folders/1/files', () =>
          HttpResponse.json({
            upload_url: 'http://new_url',
            upload_params: {
              Filename: 'file',
              key: 'folder/filename',
              'content-type': 'image/png',
            },
            file_param: 'attachment[uploaded_data]',
          }),
        ),
        http.post(
          'http://new_url',
          () =>
            new HttpResponse('yo', {
              headers: {'content-type': 'text/plain'},
            }),
        ),
      )

      const file = {name: 'file1', size: 0}
      uploadFile(file, '1', onSuccess, onFail)

      await waitFor(() => {
        expect(onSuccess).toHaveBeenCalledWith('yo')
        expect(onFail).not.toHaveBeenCalled()
      })
    })

    it('runs the onFailure method on upload failure', async () => {
      const onSuccess = vi.fn()
      const onFail = vi.fn()

      server.use(
        http.post('/api/v1/folders/1/files', () =>
          HttpResponse.json({
            upload_url: 'http://new_url',
            upload_params: {
              Filename: 'file',
              key: 'folder/filename',
              'content-type': 'image/png',
            },
            file_param: 'attachment[uploaded_data]',
          }),
        ),
        http.post('http://new_url', () => new HttpResponse('yo', {status: 400})),
      )

      const file = {name: 'file2', size: 0}
      uploadFile(file, '1', onSuccess, onFail)

      await waitFor(() => {
        expect(onFail).toHaveBeenCalled()
        expect(onSuccess).not.toHaveBeenCalled()
      })
    })
  })

  describe('onFileUploadInfoReceived', () => {
    it('runs the onFailure on file prep failure', async () => {
      const onSuccess = vi.fn()
      const onFail = vi.fn()

      server.use(
        http.post('/api/v1/folders/1/files', () =>
          HttpResponse.json({data: {formData: 'form', uploadUrl: 'new_url'}}, {status: 400}),
        ),
      )

      const file = {name: 'file2', size: 0}
      uploadFile(file, '1', onSuccess, onFail)

      await waitFor(() => {
        expect(onFail).toHaveBeenCalled()
        expect(onSuccess).not.toHaveBeenCalled()
      })
    })
  })
})
