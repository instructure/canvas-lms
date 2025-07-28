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

import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {assignLocation} from '@canvas/util/globalUtils'
import {QueryClient} from '@tanstack/react-query'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'

import UserObservees, {type Observee} from '../UserObservees'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

describe('UserObservees', () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  const userId = '1'
  const observees: Array<Observee> = [
    {
      id: '9',
      name: 'Forest Minish',
    },
    {
      id: '10',
      name: 'Link Minish',
    },
  ]
  const newObservee: Observee = {
    id: '11',
    name: 'Zelda Minish',
  }
  const POST_OBSERVEES_URI = `/api/v1/users/${userId}/observees`
  const GET_OBSERVEES_URI = `/api/v1/users/${userId}/observees?per_page=100`
  const createDeleteObserveeUri = (id: string) => `/api/v1/users/self/observees/${id}`
  const confirmMock = jest.fn().mockReturnValue(true)
  global.confirm = confirmMock

  const renderComponent = () =>
    render(
      <MockedQueryClientProvider client={queryClient}>
        <UserObservees userId={userId} />
      </MockedQueryClientProvider>,
    )

  beforeAll(() => {
    fetchMock.get(GET_OBSERVEES_URI, [])
    global.window = Object.create(window)
  })

  afterEach(() => {
    fetchMock.restore()
    jest.clearAllMocks()
  })

  describe('when no students are being observed', () => {
    it('should show the placeholder message', async () => {
      // Clear any mocks that might affect the test
      fetchMock.restore()
      fetchMock.get(GET_OBSERVEES_URI, [])

      renderComponent()

      // Use a more flexible approach to find the text
      const noStudentsMessage = await screen.findByText(content => {
        return content.trim() === 'No students being observed.'
      })
      expect(noStudentsMessage).toBeInTheDocument()
    })
  })

  describe('when failing to fetch observees', () => {
    it('should show the error message', async () => {
      fetchMock.get(
        GET_OBSERVEES_URI,
        {status: 500, body: {error: 'Unknown error'}},
        {overwriteRoutes: true},
      )
      renderComponent()

      const errorMessage = await screen.findByText('Failed to load students.')
      expect(errorMessage).toBeInTheDocument()
    })
  })

  describe('when observees are fetched successfully', () => {
    it('should show the list of observees', async () => {
      // Clear any existing mocks first
      fetchMock.restore()
      fetchMock.get(GET_OBSERVEES_URI, observees, {overwriteRoutes: true})
      renderComponent()

      const expectations = observees.map(async observee => {
        const studentName = await screen.findByText(observee.name)
        expect(studentName).toBeInTheDocument()
      })
      await Promise.all(expectations)
    })
  })

  describe('when pairing code is empty', () => {
    it('should show and error after the form is submitted', async () => {
      renderComponent()
      const submit = screen.getByLabelText('Student')

      await userEvent.click(submit)

      const errorTexts = await screen.findAllByText('Invalid pairing code.')
      expect(errorTexts.length).toBeTruthy()
    })
  })

  describe('when adding a student as observee', () => {
    describe('and the request was successful', () => {
      describe('and redirect is needed', () => {
        it('should show the built in confirm dialog and redirect', async () => {
          const redirectUrl = 'http://redirect-to.com'
          fetchMock
            .get(GET_OBSERVEES_URI, [], {overwriteRoutes: true})
            .get(GET_OBSERVEES_URI, [newObservee], {
              overwriteRoutes: true,
            })
          fetchMock.post(
            POST_OBSERVEES_URI,
            {...newObservee, redirect: redirectUrl},
            {overwriteRoutes: true},
          )
          renderComponent()
          const pairingCode = screen.getByLabelText('Student Pairing Code *')
          const submit = screen.getByLabelText('Student')

          await userEvent.type(pairingCode, '123456')
          await userEvent.click(submit)

          await waitFor(() => {
            expect(confirmMock).toHaveBeenCalled()
            expect(assignLocation).toHaveBeenCalledWith(redirectUrl)
          })
        })
      })
      describe('and no redirect needed', () => {
        it('should show the student in the list of observees and a success banner', async () => {
          fetchMock
            .get(GET_OBSERVEES_URI, [], {overwriteRoutes: true})
            .get(GET_OBSERVEES_URI, [newObservee], {overwriteRoutes: true})
          fetchMock.post(POST_OBSERVEES_URI, newObservee, {overwriteRoutes: true})
          renderComponent()
          const pairingCode = screen.getByLabelText('Student Pairing Code *')
          const submit = screen.getByLabelText('Student')

          await userEvent.type(pairingCode, '123456')
          await userEvent.click(submit)

          const banner = await screen.findAllByText(`Now observing ${newObservee.name}.`)
          const observee = await screen.findByText(newObservee.name)
          expect(observee).toBeInTheDocument()
          expect(banner.length).toBeTruthy()
          expect(pairingCode).toHaveValue('')
          expect(pairingCode).toHaveFocus()
        })
      })
    })

    describe('and the request failed', () => {
      it('should show an error banner', async () => {
        fetchMock.get(GET_OBSERVEES_URI, [], {overwriteRoutes: true})
        fetchMock.post(POST_OBSERVEES_URI, {status: 500}, {overwriteRoutes: true})
        renderComponent()
        const pairingCode = screen.getByLabelText('Student Pairing Code *')
        const submit = screen.getByLabelText('Student')

        await userEvent.type(pairingCode, '123456')
        await userEvent.click(submit)

        const errorBanners = await screen.findAllByText('Invalid pairing code.')
        expect(errorBanners.length).toBeTruthy()
        expect(pairingCode).toHaveFocus()
      })
    })
  })

  describe('when removing an observee', () => {
    describe('and the request was successful', () => {
      it('should show a success banner and remove the student from the list', async () => {
        const [observeeToDelete, ...remainingObervees] = observees
        fetchMock.get(GET_OBSERVEES_URI, observees, {overwriteRoutes: true})
        fetchMock.delete(
          createDeleteObserveeUri(observeeToDelete.id),
          {...observeeToDelete},
          {overwriteRoutes: true},
        )
        renderComponent()
        const removeButton = await screen.findByLabelText(`Remove ${observeeToDelete.name}`)

        fetchMock.get(GET_OBSERVEES_URI, remainingObervees, {overwriteRoutes: true})
        await userEvent.click(removeButton)

        const banner = await screen.findAllByText(`No longer observing ${observeeToDelete.name}.`)
        const observee = screen.queryByText(observeeToDelete.name)
        expect(observee).not.toBeInTheDocument()
        expect(banner.length).toBeTruthy()
      })
    })

    describe('and the request failed', () => {
      it('should show an error banner', async () => {
        const [observeeToDelete] = observees
        fetchMock.get(GET_OBSERVEES_URI, observees, {overwriteRoutes: true})
        fetchMock.delete(
          createDeleteObserveeUri(observeeToDelete.id),
          {status: 500},
          {
            overwriteRoutes: true,
          },
        )
        renderComponent()
        const removeButton = await screen.findByLabelText(`Remove ${observeeToDelete.name}`)

        await userEvent.click(removeButton)

        const errorBanners = await screen.findAllByText('Failed to remove student.')
        expect(errorBanners.length).toBeTruthy()
      })
    })
  })
})
