/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {
  getRelevantUserFromEnrollment,
  groupEnrollmentsByPairingId,
  TempEnrollView,
} from '../TempEnrollView'
import React from 'react'
import {fireEvent, render, screen, waitFor, act} from '@testing-library/react'
import {type Enrollment, ITEMS_PER_PAGE, PROVIDER, RECIPIENT, type User} from '../types'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'

const server = setupServer()

const renderView = async (props: any) => {
  let result!: ReturnType<typeof render>
  await act(async () => {
    result = render(
      <MockedQueryProvider>
        <TempEnrollView {...props} />
      </MockedQueryProvider>,
    )
  })
  return result
}

describe('TempEnrollView component', () => {
  window.confirm = vi.fn(() => true)

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
  })

  const defaultProvider = {
    name: 'Provider User',
    avatar_url: 'https://someurl.com/avatar.png',
    id: '1234',
  }

  const defaultRecipient = {
    name: 'Recipient User',
    id: '6789',
  }

  const defaultEnrollment = {
    id: '1',
    course_id: '1',
    user: defaultRecipient,
    temporary_enrollment_pairing_id: 10,
    start_at: '2021-01-01T00:00:00Z',
    end_at: '2021-02-01T00:00:00Z',
    type: 'TeacherEnrollment',
  }

  const props = {
    user: defaultProvider,
    onEdit: vi.fn(),
    onDelete: vi.fn(),
    onAddNew: vi.fn(),
    disableModal: vi.fn(),
    enrollmentType: PROVIDER,
    modifyPermissions: {
      canAdd: true,
      canDelete: true,
      canEdit: true,
    },
  }

  const ENROLLMENTS_URL = `/api/v1/users/${defaultProvider.id}/enrollments`

  afterEach(() => {
    vi.restoreAllMocks()
    server.resetHandlers()
    // reset cache between tests
    queryClient.removeQueries()
  })

  afterAll(() => server.close())

  it('renders component', async () => {
    server.use(
      http.get(ENROLLMENTS_URL, () =>
        HttpResponse.json([defaultEnrollment], {
          headers: {link: '<current_url>; rel="current"'},
        }),
      ),
    )
    const container = (await renderView(props)).container

    expect(await screen.findByText(props.user.name)).toBeInTheDocument()

    const avatar = container.querySelector('span > img')
    expect(avatar).toBeInTheDocument()
    expect(avatar).toHaveAttribute('src', props.user.avatar_url)

    const rpText = screen.getByText('PU')
    expect(rpText).toBeInTheDocument()
  })

  describe('table headers', () => {
    it("displays the provider's table headers", async () => {
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([defaultEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )
      await renderView(props)

      expect(await screen.findByText('Recipient Name')).toBeInTheDocument()
      expect(screen.getByText('Recipient Enrollment Period')).toBeInTheDocument()
      expect(screen.getByText('Recipient Enrollment Type')).toBeInTheDocument()
      expect(screen.getByText('Status')).toBeInTheDocument()
      expect(screen.getByText('Temporary enrollment option links')).toBeInTheDocument()
    })

    it("displays the recipient's table headers", async () => {
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([defaultEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )
      await renderView({...props, enrollmentType: RECIPIENT})

      expect(await screen.findByText('Provider Name')).toBeInTheDocument()
      expect(screen.getByText('Recipient Enrollment Period')).toBeInTheDocument()
      expect(screen.getByText('Recipient Enrollment Type')).toBeInTheDocument()
      expect(screen.getByText('Status')).toBeInTheDocument()
      expect(screen.getByText('Temporary enrollment option links')).toBeInTheDocument()
    })

    it('does not display options links if permissions are not set', async () => {
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([defaultEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )
      const newProps = {
        ...props,
        modifyPermissions: {
          canAdd: false,
          canDelete: false,
          canEdit: false,
        },
      }
      await renderView(newProps)

      expect(
        await waitFor(() => screen.queryByText('Temporary enrollment option links')),
      ).not.toBeInTheDocument()
    })
  })

  describe('renderEnrollmentPairingStatus', () => {
    it('returns a Pill with "Future" status for future enrollments', async () => {
      const futureDate = new Date()
      futureDate.setFullYear(futureDate.getFullYear() + 1)
      const futureEnrollment = {
        ...defaultEnrollment,
        start_at: futureDate.toISOString(),
      }
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([futureEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )

      const {findByText} = await renderView(props)
      expect(await findByText('Future')).toBeInTheDocument()
    })

    it('returns a Pill with "Active" status for past enrollments', async () => {
      const pastDate = new Date()
      pastDate.setFullYear(pastDate.getFullYear() - 1)
      const activeEnrollment = {
        ...defaultEnrollment,
        start_at: pastDate.toISOString(),
      }
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([activeEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )

      const {findByText} = await renderView(props)
      expect(await findByText('Active')).toBeInTheDocument()
    })

    it('returns a Pill with "Active" status when start_at is not present', async () => {
      const nullEnrollment = {
        ...defaultEnrollment,
        start_at: null,
      }
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([nullEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )

      const {findByText} = await renderView(props)
      expect(await findByText('Active')).toBeInTheDocument()
    })
  })

  describe('action button visibility based on permissions', () => {
    beforeEach(() => {
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([defaultEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )
    })

    it('shows Edit and Delete buttons based on canEdit and canDelete', async () => {
      await renderView(props)

      expect(await screen.findByTestId('edit-button')).toBeInTheDocument()
      expect(await screen.findByTestId('delete-button')).toBeInTheDocument()
    })

    it('does not show Edit button based on canEdit being false', async () => {
      const newProps = {
        ...props,
        modifyPermissions: {
          ...props.modifyPermissions,
          canEdit: false,
        },
      }

      await renderView(newProps)

      expect(await screen.findByTestId('delete-button')).toBeInTheDocument()
      expect(screen.queryByTestId('edit-button')).not.toBeInTheDocument()
    })

    it('does not show Delete button based on canDelete being false', async () => {
      const newProps = {
        ...props,
        modifyPermissions: {
          ...props.modifyPermissions,
          canDelete: false,
        },
      }

      await renderView(newProps)

      expect(await screen.findByTestId('edit-button')).toBeInTheDocument()
      expect(screen.queryByTestId('delete-button')).not.toBeInTheDocument()
    })

    it('shows "Add New" button based on canAdd and enrollmentType', async () => {
      await renderView(props)

      expect(await screen.findByTestId('add-button')).toBeInTheDocument()
    })

    it('does not show "Add New" button based on recipient enrollmentType', async () => {
      const newProps = {
        ...props,
        enrollmentType: RECIPIENT,
      }
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([defaultEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )

      await renderView(newProps)

      await waitFor(() => expect(screen.queryByTestId('add-button')).not.toBeInTheDocument())
    })

    it('does not show "Add New" button based on addNew being false', async () => {
      const newProps = {
        ...props,
        modifyPermissions: {
          ...props.modifyPermissions,
          canAdd: false,
        },
      }

      await renderView(newProps)

      await waitFor(() => expect(screen.queryByTestId('add-button')).not.toBeInTheDocument())
    })
  })

  describe('buttons', () => {
    beforeEach(() => {
      server.use(
        http.get(ENROLLMENTS_URL, () =>
          HttpResponse.json([defaultEnrollment], {
            headers: {link: '<current_url>; rel="current"'},
          }),
        ),
      )
    })

    describe('edit', () => {
      it('calls onEdit with correct enrollment data when clicked', async () => {
        await renderView(props)
        await waitFor(() => fireEvent.click(screen.getByTestId('edit-button')))
        expect(props.onEdit).toHaveBeenCalledWith(defaultEnrollment.user, [defaultEnrollment])
      })
    })

    describe('delete', () => {
      beforeEach(() => {
        server.use(
          http.delete(
            `/api/v1/courses/${defaultEnrollment.course_id}/enrollments/${defaultEnrollment.id}`,
            () => HttpResponse.json({}),
          ),
        )
        window.confirm = vi.fn(() => true)
      })

      it('opens a confirmation dialog when delete button is clicked', async () => {
        await renderView(props)
        await waitFor(() => fireEvent.click(screen.getByTestId('delete-button')))
        expect(window.confirm).toHaveBeenCalled()
      })

      it('does not perform deletion if user cancels confirmation', async () => {
        window.confirm = vi.fn(() => false)
        await renderView(props)
        await waitFor(() => fireEvent.click(screen.getByTestId('delete-button')))
        expect(await screen.findByText('Recipient User')).toBeInTheDocument()
      })

      it('alerts when deletion is successful after confirming', async () => {
        await renderView(props)
        await waitFor(() => fireEvent.click(screen.getByTestId('delete-button')))
        await waitFor(() =>
          expect(
            screen.queryAllByText('1 enrollments deleted successfully.')[0],
          ).toBeInTheDocument(),
        )
      })
    })

    describe('add new', () => {
      it('calls onAddNew when clicked', async () => {
        await renderView(props)
        await waitFor(() => fireEvent.click(screen.getByTestId('add-button')))

        expect(props.onAddNew).toHaveBeenCalled()
      })
    })
  })

  describe('utility functions', () => {
    const mockProviderUser: User = {
      id: '1',
      name: 'Provider User',
    }
    const mockRecipientUser: User = {
      id: '2',
      name: 'Recipient User',
    }
    const mockTempEnrollment: Enrollment = {
      course_id: '0',
      end_at: '',
      id: '0',
      role_id: '',
      start_at: '',
      enrollment_state: '',
      temporary_enrollment_source_user_id: 0,
      type: '',
      limit_privileges_to_course_section: false,
      user: mockRecipientUser,
      temporary_enrollment_provider: mockProviderUser,
      temporary_enrollment_pairing_id: 1,
    }

    describe('getRelevantUserFromEnrollment', () => {
      it('returns temporary_enrollment_provider when present', () => {
        const enrollmentUser: User = getRelevantUserFromEnrollment(mockTempEnrollment)
        expect(enrollmentUser).toBe(mockTempEnrollment.temporary_enrollment_provider)
      })

      it('returns user when temporary_enrollment_provider is absent', () => {
        const tempEnrollment: Enrollment = {
          ...mockTempEnrollment,
          temporary_enrollment_provider: undefined,
        }
        const enrollmentUser = getRelevantUserFromEnrollment(tempEnrollment)
        expect(enrollmentUser).toBe(tempEnrollment.user)
      })
    })

    describe('groupEnrollmentsByPairingId', () => {
      it('groups enrollments by temporary_enrollment_pairing_id', () => {
        const tempEnrollment2: Enrollment = {
          ...mockTempEnrollment,
          temporary_enrollment_pairing_id: 2,
        }
        const tempEnrollment3: Enrollment = {
          ...mockTempEnrollment,
          temporary_enrollment_pairing_id: 2,
        }
        const tempEnrollments = [mockTempEnrollment, tempEnrollment2, tempEnrollment3]
        const grouped = groupEnrollmentsByPairingId(tempEnrollments)
        expect(Object.keys(grouped)).toHaveLength(2)
        expect(grouped[1]).toHaveLength(1)
        expect(grouped[1][0]).toBe(tempEnrollments[0])
        expect(grouped[2]).toHaveLength(2)
        expect(grouped[2][0]).toBe(tempEnrollments[1])
        expect(grouped[2][1]).toBe(tempEnrollments[2])
      })
    })
  })
})
