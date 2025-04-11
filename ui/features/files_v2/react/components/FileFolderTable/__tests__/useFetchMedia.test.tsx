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

import {useFetchMedia, useFetchMediaProps} from '../useFetchMedia'
import {renderHook} from '@testing-library/react-hooks'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import fetchMock from 'fetch-mock'

const defaultProps: useFetchMediaProps = {
  attachmentId: '1',
  enabled: true,
}

const fakeMediaSources = [{url: 'http://example.com'}]

const renderHookComponent = (props?: Partial<useFetchMediaProps>) => {
  return renderHook(() => useFetchMedia({...defaultProps, ...props}), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
    ),
  })
}

describe('useFetchMedia', () => {
  beforeEach(() => {
    fetchMock.get(/.*\/media_attachments\/1\/info/, {media_sources: fakeMediaSources})
  })

  afterEach(() => {
    fetchMock.restore()
    queryClient.clear()
  })

  it('fetches media info', async () => {
    const {result, waitFor} = renderHookComponent()
    await waitFor(() => {
      expect(result.current.data).toEqual({media_sources: fakeMediaSources})
    })
  })

  it('returns undefined on error', async () => {
    fetchMock.get(/.*\/media_attachments\/1\/info/, {ok: false}, {overwriteRoutes: true})
    const {result, waitFor} = renderHookComponent()
    await waitFor(() => {
      expect(result.current.data).toBeUndefined()
    })
  })

  it('does not fetch when disabled', async () => {
    const {result, waitFor} = renderHookComponent({enabled: false})
    await waitFor(() => {
      expect(result.current.data).toBeUndefined()
    })
  })

  it('does not retry', async () => {
    fetchMock.get(/.*\/media_attachments\/1\/info/, {ok: false}, {overwriteRoutes: true})
    const {result, waitFor} = renderHookComponent()
    await waitFor(() => {
      expect(result.current.data).toBeUndefined()
    })
    expect(fetchMock.calls()).toHaveLength(1)
  })
})
