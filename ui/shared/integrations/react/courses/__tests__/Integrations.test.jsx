/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {render, act, fireEvent, waitFor} from '@testing-library/react'
import React from 'react'
import Integrations from '../Integrations'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('Integrations', () => {
  const oldENV = window.ENV

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    window.ENV = {
      COURSE_ID: 2,
      MSFT_SYNC_ENABLED: true,
    }
  })

  afterEach(() => {
    server.resetHandlers()
    window.ENV = oldENV
  })

  it('renders the Microsoft Sync integration', async () => {
    server.use(http.get('/api/v1/courses/2/microsoft_sync/group', () => HttpResponse.json({})))
    const subject = render(<Integrations />)
    await waitFor(() => {
      expect(subject.getAllByText('Microsoft Sync')).toBeTruthy()
    })
  })

  describe('when no integrations are enabled', () => {
    beforeEach(() => {
      window.ENV.MSFT_SYNC_ENABLED = false
    })

    it('informs the user no integrations are available', () => {
      expect(render(<Integrations />).getByText('No integrations available')).toBeInTheDocument()
    })

    it("doesn't fetch from the API", () => {
      let requestMade = false
      server.use(
        http.get('/api/v1/courses/2/microsoft_sync/group', () => {
          requestMade = true
          return HttpResponse.json({})
        }),
      )
      act(() => {
        render(<Integrations />)
      })
      expect(requestMade).toBe(false)
    })
  })

  describe('Microsoft Sync', () => {
    it('shows errors when they exist', async () => {
      server.use(
        http.get(
          '/api/v1/courses/2/microsoft_sync/group',
          () => new HttpResponse(null, {status: 500}),
        ),
      )

      const subject = render(<Integrations />)
      await waitFor(() => {
        expect(subject.getByText('Integration error')).toBeInTheDocument()
      })

      act(() => {
        fireEvent.click(subject.getByText('Show Microsoft Sync details'))
      })

      expect(subject.getByText(/An error occurred, please try again/)).toBeInTheDocument()
    })

    it('disables the integration when toggled', async () => {
      server.use(
        http.get('/api/v1/courses/2/microsoft_sync/group', () =>
          HttpResponse.json({workflow_state: 'active'}),
        ),
        http.delete('/api/v1/courses/2/microsoft_sync/group', () => HttpResponse.json({})),
      )

      const subject = render(<Integrations />)

      await waitFor(() => {
        expect(subject.getByLabelText('Toggle Microsoft Sync')).toBeInTheDocument()
      })

      act(() => {
        fireEvent.click(subject.getByLabelText('Toggle Microsoft Sync'))
      })

      await waitFor(() => {
        expect(subject.getByLabelText('Toggle Microsoft Sync').checked).toBeTruthy()
      })
    })

    it('renders a sync button', async () => {
      server.use(
        http.get('/api/v1/courses/2/microsoft_sync/group', () =>
          HttpResponse.json({workflow_state: 'active'}),
        ),
      )

      const subject = render(<Integrations />)

      await waitFor(() => {
        expect(subject.queryByText('Show Microsoft Sync details')).toBeInTheDocument()
      })

      act(() => {
        fireEvent.click(subject.getByText('Show Microsoft Sync details'))
      })

      expect(subject.getByText('Sync Now')).toBeTruthy()
    })

    it('expands the Microsoft Sync details when toggled on', async () => {
      server.use(
        http.get(
          '/api/v1/courses/2/microsoft_sync/group',
          () => new HttpResponse(null, {status: 404}),
        ),
        http.post('/api/v1/courses/2/microsoft_sync/group', () =>
          HttpResponse.json({workflow_state: 'active'}),
        ),
      )
      const subject = render(<Integrations />)
      await waitFor(() => {
        expect(subject.queryByText('Sync Now')).not.toBeInTheDocument()
      })

      act(() => {
        fireEvent.click(subject.getByLabelText('Toggle Microsoft Sync'))
      })

      await waitFor(() => {
        expect(subject.getByText('Sync Now')).toBeTruthy()
      })
    })

    describe('when the integration is disabled', () => {
      beforeEach(() => {
        server.use(
          http.get('/api/v1/courses/2/microsoft_sync/group', () => HttpResponse.json({})),
          http.post('/api/v1/courses/2/microsoft_sync/group', () => HttpResponse.json({})),
        )
      })

      it('enables the integration when toggled', async () => {
        const subject = render(<Integrations />)

        await waitFor(() => {
          expect(subject.getByLabelText('Toggle Microsoft Sync')).toBeInTheDocument()
        })

        act(() => {
          fireEvent.click(subject.getByLabelText('Toggle Microsoft Sync'))
        })

        await waitFor(() => {
          expect(subject.getByLabelText('Toggle Microsoft Sync').checked).toBeFalsy()
        })
      })
    })
  })
})
