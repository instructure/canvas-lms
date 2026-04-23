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

import {describe, it, expect, vi, beforeAll, beforeEach, afterEach, afterAll} from 'vitest'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {CanvasNotebookApi} from '../CanvasNotebookApi'
import {request} from 'graphql-request'
import {EXECUTE_REDWOOD_QUERY} from '../queries'

vi.mock('graphql-request', () => ({
  request: vi.fn(),
}))

const mockRequest = vi.mocked(request)

const JOURNEY_URL = 'https://journey.test'
// btoa wraps the token so getJwt() can atob() it
const FAKE_JWT = btoa('decoded-jwt-token')

const server = setupServer(http.post('/api/v1/jwts', () => HttpResponse.json({token: FAKE_JWT})))

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

function makeRedwoodResponse(data: unknown) {
  return {
    executeRedwoodQuery: {
      data,
      errors: null,
    },
  }
}

function makeRedwoodErrorResponse(messages: string[]) {
  return {
    executeRedwoodQuery: {
      data: null,
      errors: messages.map(message => ({message})),
    },
  }
}

describe('CanvasNotebookApi', () => {
  let api: CanvasNotebookApi

  beforeEach(() => {
    vi.clearAllMocks()
    api = new CanvasNotebookApi(JOURNEY_URL)
  })

  describe('JWT caching', () => {
    it('fetches a JWT on the first call', async () => {
      let capturedUrl: string | undefined
      server.use(
        http.post('/api/v1/jwts', ({request: jwtRequest}) => {
          capturedUrl = jwtRequest.url
          return HttpResponse.json({token: FAKE_JWT})
        }),
      )
      mockRequest.mockResolvedValue(makeRedwoodResponse({deleteNote: '1'}))

      await api.deleteNote('1')

      expect(capturedUrl).toContain('/api/v1/jwts')
      expect(capturedUrl).toContain('canvas_audience=false&workflows[]=journey&workflows[]=redwood')
    })

    it('reuses the cached JWT on subsequent calls', async () => {
      let jwtFetchCount = 0
      server.use(
        http.post('/api/v1/jwts', () => {
          jwtFetchCount++
          return HttpResponse.json({token: FAKE_JWT})
        }),
      )
      mockRequest.mockResolvedValue(makeRedwoodResponse({deleteNote: '1'}))

      await api.deleteNote('1')
      await api.deleteNote('2')

      expect(jwtFetchCount).toBe(1)
    })

    it('retries JWT fetch after a failure', async () => {
      let jwtFetchCount = 0
      server.use(
        http.post('/api/v1/jwts', () => {
          jwtFetchCount++
          if (jwtFetchCount === 1) {
            return new HttpResponse(null, {status: 401})
          }
          return HttpResponse.json({token: FAKE_JWT})
        }),
      )
      mockRequest.mockResolvedValue(makeRedwoodResponse({deleteNote: '1'}))

      await expect(api.deleteNote('1')).rejects.toThrow()

      await api.deleteNote('1')

      expect(jwtFetchCount).toBe(2)
    })
  })

  describe('getNotes', () => {
    const notesData = {
      notes: {
        nodes: [
          {
            id: '1',
            userId: 'u1',
            courseId: 'c1',
            objectId: 'p1',
            objectType: 'Page',
            userText: 'my note',
            reaction: ['Important'],
            highlightData: {selectedText: 'hello'},
            rootAccountUuid: 'ra1',
            createdAt: '2026-01-01',
            updatedAt: '2026-01-01',
          },
        ],
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'c1',
          endCursor: 'c2',
        },
      },
    }

    it('returns paginated notes', async () => {
      mockRequest.mockResolvedValue(makeRedwoodResponse(notesData))

      const result = await api.getNotes({pageSize: 10})

      expect(result.notes).toHaveLength(1)
      expect(result.notes[0].id).toBe('1')
      expect(result.pageInfo.hasNextPage).toBe(true)
      expect(result.pageInfo.endCursor).toBe('c2')
    })

    it('passes filter and pagination params', async () => {
      mockRequest.mockResolvedValue(makeRedwoodResponse(notesData))

      await api.getNotes({
        filter: {courseId: 'c1'},
        pageSize: 5,
        direction: 'next',
        cursor: 'cursor-abc',
      })

      expect(mockRequest).toHaveBeenCalledWith(
        `${JOURNEY_URL}/graphql`,
        EXECUTE_REDWOOD_QUERY,
        {
          input: {
            query: expect.stringContaining('query GetNotes'),
            variables: {
              filter: {courseId: 'c1'},
              first: 5,
              last: null,
              after: 'cursor-abc',
              before: null,
            },
            operationName: 'GetNotes',
          },
        },
        {Authorization: 'Bearer decoded-jwt-token'},
      )
    })

    it('passes cursor as before when direction is prev', async () => {
      mockRequest.mockResolvedValue(makeRedwoodResponse(notesData))

      await api.getNotes({direction: 'prev', cursor: 'cursor-xyz'})

      expect(mockRequest).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(String),
        expect.objectContaining({
          input: expect.objectContaining({
            variables: expect.objectContaining({
              first: null,
              last: 10,
              before: 'cursor-xyz',
              after: null,
            }),
          }),
        }),
        expect.any(Object),
      )
    })
  })

  describe('createNote', () => {
    it('creates a note and returns it', async () => {
      const newNote = {
        id: '2',
        userId: 'u1',
        courseId: 'c1',
        objectId: 'p1',
        objectType: 'Page',
        userText: 'new note',
        reaction: ['Important'],
        highlightData: {selectedText: 'text'},
        rootAccountUuid: 'ra1',
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      }
      mockRequest.mockResolvedValue(makeRedwoodResponse({createNote: newNote}))

      const result = await api.createNote({
        courseId: 'c1',
        objectId: 'p1',
        objectType: 'Page',
        reaction: ['Important'],
        highlightData: {
          selectedText: 'text',
          textPosition: null,
          range: null,
          pageLastModifiedAt: '2026-01-01',
        },
      } as Parameters<typeof api.createNote>[0])

      expect(result).toEqual(newNote)
    })
  })

  describe('updateNote', () => {
    it('updates a note and returns it', async () => {
      const updatedNote = {
        id: '1',
        userId: 'u1',
        courseId: 'c1',
        objectId: 'p1',
        objectType: 'Page',
        userText: 'updated text',
        reaction: ['Confusing'],
        highlightData: {selectedText: 'text'},
        rootAccountUuid: 'ra1',
        createdAt: '2026-01-01',
        updatedAt: '2026-01-02',
      }
      mockRequest.mockResolvedValue(makeRedwoodResponse({updateNote: updatedNote}))

      const result = await api.updateNote('1', {
        id: '1',
        reaction: ['Confusing'],
        highlightData: {
          selectedText: 'text',
          textPosition: null,
          range: null,
          pageLastModifiedAt: '2026-01-01',
        },
      } as Parameters<typeof api.updateNote>[1])

      expect(result).toEqual(updatedNote)
    })

    it('includes the id in the variables', async () => {
      mockRequest.mockResolvedValue(makeRedwoodResponse({updateNote: {id: '1'}}))

      await api.updateNote('1', {
        id: '1',
        reaction: ['Important'],
        highlightData: {
          selectedText: 'text',
          textPosition: null,
          range: null,
          pageLastModifiedAt: '2026-01-01',
        },
      } as Parameters<typeof api.updateNote>[1])

      expect(mockRequest).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(String),
        expect.objectContaining({
          input: expect.objectContaining({
            variables: expect.objectContaining({id: '1'}),
          }),
        }),
        expect.any(Object),
      )
    })
  })

  describe('deleteNote', () => {
    it('deletes a note without returning data', async () => {
      mockRequest.mockResolvedValue(makeRedwoodResponse({deleteNote: '1'}))

      await expect(api.deleteNote('1')).resolves.toBeUndefined()
    })
  })

  describe('error handling', () => {
    it('throws on Redwood errors', async () => {
      mockRequest.mockResolvedValue(makeRedwoodErrorResponse(['Note not found', 'Access denied']))

      await expect(api.deleteNote('999')).rejects.toThrow('Note not found; Access denied')
    })

    it('throws when no data is returned', async () => {
      mockRequest.mockResolvedValue({
        executeRedwoodQuery: {data: null, errors: null},
      })

      await expect(api.deleteNote('1')).rejects.toThrow('No data returned from Redwood')
    })
  })
})
