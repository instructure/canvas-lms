/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import axios from 'axios'
import {beforeEach, describe, expect, it, vi} from 'vitest'
import {doAsrRequest} from '../doAsrRequest'

vi.mock('axios')

describe('doAsrRequest', () => {
  beforeEach(() => {
    vi.mocked(axios.post).mockResolvedValue({status: 201})
  })

  it('calls the attachment URL when attachmentId is provided', async () => {
    await doAsrRequest({attachmentId: '42'}, 'en')

    expect(axios.post).toHaveBeenCalledWith('/api/v1/media_attachments/42/asr', expect.any(Object))
  })

  it('calls the media object URL when mediaObjectId is provided', async () => {
    await doAsrRequest({mediaObjectId: 'm-abc'}, 'es')

    expect(axios.post).toHaveBeenCalledWith('/api/v1/media_objects/m-abc/asr', expect.any(Object))
  })

  it('prefers attachmentId over mediaObjectId when both are provided', async () => {
    await doAsrRequest({attachmentId: '42', mediaObjectId: 'm-abc'}, 'en')

    expect(axios.post).toHaveBeenCalledWith('/api/v1/media_attachments/42/asr', expect.any(Object))
  })

  it('sends locale in the JSON body', async () => {
    await doAsrRequest({attachmentId: '42'}, 'fr')

    expect(axios.post).toHaveBeenCalledWith(expect.any(String), {locale: 'fr'})
  })

  it('resolves on a 2xx response', async () => {
    await expect(doAsrRequest({attachmentId: '42'}, 'en')).resolves.toBeUndefined()
  })

  it('rejects on a non-ok response', async () => {
    vi.mocked(axios.post).mockRejectedValue(new Error('Request failed with status code 400'))

    await expect(doAsrRequest({attachmentId: '42'}, 'en')).rejects.toThrow(
      'Request failed with status code 400',
    )
  })

  it('throws when neither attachmentId nor mediaObjectId is provided', async () => {
    await expect(doAsrRequest({}, 'en')).rejects.toThrow(
      'Either mediaObjectId or attachmentId must be provided',
    )
  })
})
