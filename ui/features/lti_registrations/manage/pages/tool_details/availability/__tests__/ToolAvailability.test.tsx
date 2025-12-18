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

import {fireEvent, screen, waitFor} from '@testing-library/react'
import {success} from '../../../../../common/lib/apiResult/ApiResult'
import type {ApiResult} from '../../../../../common/lib/apiResult/ApiResult'
import type {FetchControlsByDeployment} from '../../../../api/contextControls'
import {ZAccountId} from '../../../../model/AccountId'
import {ZCourseId} from '../../../../model/CourseId'
import {ZLtiContextControlId} from '../../../../model/LtiContextControl'
import {ZLtiDeploymentId} from '../../../../model/LtiDeploymentId'
import type {LtiDeployment} from '../../../../model/LtiDeployment'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'
import {mockRegistrationWithAllInformation} from '../../../manage/__tests__/helpers'
import {renderAppWithRegistration} from '../../configuration/__tests__/helpers'
import {ToolAvailability} from '../ToolAvailability'
import {mockContextControl, mockDeployment} from './helpers'
import fakeENV from '@canvas/test-utils/fakeENV'
import {createDeployment} from '../../../../api/deployments'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
  showFlashSuccess: vi.fn(() => vi.fn()),
  showFlashError: vi.fn(() => vi.fn()),
}))
const mockFlash = showFlashAlert as ReturnType<typeof vi.fn>

vi.mock('../../../../api/deployments', async () => {
  const actual = await vi.importActual('../../../../api/deployments')
  return {
    ...actual,
    createDeployment: vi.fn(),
  }
})

const page1Deployments = [
  mockDeployment({
    id: ZLtiDeploymentId.parse('dep-1'),
    context_id: '2',
    context_type: 'Account',
    context_controls: [
      // root control
      mockContextControl({
        id: ZLtiContextControlId.parse('cc-1-1'),
        context_name: 'CC-1-1',
        account_id: ZAccountId.parse('2'),
        path: 'a2.',
      }),
      mockContextControl({
        id: ZLtiContextControlId.parse('cc-1-2'),
        context_name: 'CC-1-2',
        account_id: ZAccountId.parse('3'),
        path: 'a2.a3.',
      }),
      mockContextControl({
        id: ZLtiContextControlId.parse('cc-1-3'),
        context_name: 'CC-1-3',
        account_id: ZAccountId.parse('4'),
        path: 'a2.a4.',
      }),
      mockContextControl({
        id: ZLtiContextControlId.parse('cc-1-4'),
        context_name: 'CC-1-4',
        account_id: ZAccountId.parse('5'),
        path: 'a2.a5.',
      }),
    ],
  }),
]
const page2Deployments = [
  mockDeployment({
    id: ZLtiDeploymentId.parse('dep-1'),
    context_id: '2',
    context_type: 'Account',
    context_controls: [
      mockContextControl({
        id: ZLtiContextControlId.parse('cc-1-5'),
        context_name: 'CC-1-5',
        account_id: ZAccountId.parse('12'),
        path: 'a2.a12.',
      }),
      mockContextControl({
        id: ZLtiContextControlId.parse('cc-1-6'),
        context_name: 'CC-1-6',
        account_id: ZAccountId.parse('13'),
        path: 'a2.a13.',
      }),
    ],
  }),
  mockDeployment({
    id: ZLtiDeploymentId.parse('dep-2'),
    deployment_id: ZLtiDeploymentId.parse('default-deployment-id-2'),
    context_id: '2',
    context_type: 'Account',
    context_controls: [
      // root control
      mockContextControl({
        id: ZLtiContextControlId.parse('cc-2-1'),
        account_id: ZAccountId.parse('2'),
        context_name: 'CC-2-1',
        path: 'a2.a1.',
      }),
      mockContextControl({
        id: ZLtiContextControlId.parse('cc-2-2'),
        context_name: 'CC-2-2',
        path: 'a2.a2.',
      }),
    ],
  }),
]

describe('ToolAvailability', () => {
  beforeAll(() => {
    fakeENV.setup({
      ACCOUNT_ID: '1',
    })
  })

  afterAll(() => {
    fakeENV.teardown()
  })

  it('renders the header text', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })
    const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([]))
    const accountId = ZAccountId.parse('1')
    const screen = renderAppWithRegistration(reg)(
      <ToolAvailability
        deleteDeployment={vi.fn()}
        editContextControl={vi.fn()}
        accountId={accountId}
        fetchControlsByDeployment={fetchControlsByDeployment}
        deleteContextControl={vi.fn()}
      />,
    )
    expect(fetchControlsByDeployment).toHaveBeenCalled()

    await screen.findByText(/Control Test App's availability/)
    const alertText = await screen.findByText(
      /This tool hasn't been deployed to any sub-accounts or courses./,
    )
    expect(alertText).toBeInTheDocument()
  })

  it('renders a Create Deployment button that calls the create deployment endpoint', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })
    const newDeployment = mockDeployment({
      id: ZLtiDeploymentId.parse('new-dep-1'),
      context_name: 'Test Account',
      context_id: reg.account_id,
      context_type: 'Account',
      registration_id: ZLtiRegistrationId.parse(reg.id),
      context_controls: [
        mockContextControl({
          id: ZLtiContextControlId.parse('cc-new-1'),
          account_id: ZAccountId.parse(reg.account_id),
          context_name: 'Test Account',
          path: `a${reg.account_id}.`,
        }),
      ],
    })

    const mockCreateDeployment = createDeployment as ReturnType<typeof vi.fn>
    mockCreateDeployment.mockResolvedValue(success(newDeployment))

    const fetchControlsByDeployment = vi.fn()
    // First call returns empty, second call (after create) returns the new deployment
    fetchControlsByDeployment
      .mockResolvedValueOnce(success([]))
      .mockResolvedValueOnce(success([newDeployment]))

    const accountId = ZAccountId.parse(reg.account_id)
    const utils = renderAppWithRegistration(reg)(
      <ToolAvailability
        deleteDeployment={vi.fn()}
        editContextControl={vi.fn()}
        accountId={accountId}
        fetchControlsByDeployment={fetchControlsByDeployment}
        deleteContextControl={vi.fn()}
      />,
    )

    // Wait for initial render with no deployments
    await utils.findByText(/Control Test App's availability/)

    // Verify the Create Deployment button is visible
    const button = await utils.findByText('Create Deployment')
    expect(button).toBeInTheDocument()

    fireEvent.click(button)

    // Verify createDeployment was called with correct params
    await waitFor(() => {
      expect(mockCreateDeployment).toHaveBeenCalledWith({
        registrationId: reg.id,
        accountId: accountId,
        available: false,
      })
    })

    // Verify the query was refetched to show the new deployment
    expect(fetchControlsByDeployment).toHaveBeenCalledTimes(2)

    // Check that the deployment list is now showing
    await waitFor(() => {
      expect(utils.getByText('Installed in Test Account')).toBeInTheDocument()
    })
  })

  it('shows an error when creating a deployment fails', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })

    const mockCreateDeployment = createDeployment as ReturnType<typeof vi.fn>
    mockCreateDeployment.mockResolvedValue({
      _type: 'GenericError' as const,
      message: 'Failed to create deployment',
    })

    const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([]))
    const accountId = ZAccountId.parse(reg.account_id)

    const utils = renderAppWithRegistration(reg)(
      <ToolAvailability
        deleteDeployment={vi.fn()}
        editContextControl={vi.fn()}
        accountId={accountId}
        fetchControlsByDeployment={fetchControlsByDeployment}
        deleteContextControl={vi.fn()}
      />,
    )

    // Wait for initial render
    await utils.findByText(/Control Test App's availability/)

    const button = await utils.findByText('Create Deployment')
    fireEvent.click(button)

    // Verify error message was shown
    await waitFor(() => {
      expect(mockFlash).toHaveBeenCalledWith({
        type: 'error',
        message: 'There was an error when creating the deployment',
      })
    })

    // Verify the query was not refetched
    expect(fetchControlsByDeployment).toHaveBeenCalledTimes(1)
  })

  it('disables the Create Deployment button while creating', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })

    const mockCreateDeployment = createDeployment as ReturnType<typeof vi.fn>
    let resolveCreate: () => void = () => {}
    const createPromise = new Promise<ApiResult<LtiDeployment>>(resolve => {
      resolveCreate = () => resolve(success(mockDeployment()))
    })
    mockCreateDeployment.mockReturnValue(createPromise)

    const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([]))
    const accountId = ZAccountId.parse(reg.account_id)

    const utils = renderAppWithRegistration(reg)(
      <ToolAvailability
        deleteDeployment={vi.fn()}
        editContextControl={vi.fn()}
        accountId={accountId}
        fetchControlsByDeployment={fetchControlsByDeployment}
        deleteContextControl={vi.fn()}
      />,
    )

    const button = await utils.findByText('Create Deployment')
    expect(button).not.toBeDisabled()

    fireEvent.click(button)

    // Button should be disabled while creating
    await waitFor(() => {
      expect(button.closest('button')).toBeDisabled()
    })

    // Resolve the promise
    resolveCreate()

    // Button should be enabled again after creation
    await waitFor(() => {
      expect(fetchControlsByDeployment).toHaveBeenCalledTimes(2)
    })
  })

  it('renders all deployments', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })
    const deployments = [
      mockDeployment({
        context_name: 'Test Account',
        context_id: '1',
        context_type: 'Account',
        context_controls: [
          mockContextControl({
            account_id: ZAccountId.parse('1'),
            path: 'a1.',
          }),
        ],
      }),
      mockDeployment({
        id: ZLtiDeploymentId.parse('2'),
        context_type: 'Course',
        context_id: '10',
        context_name: 'Course 1',
        registration_id: ZLtiRegistrationId.parse('1'),
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-course-1'),
            context_name: 'Test Course 101',
            course_id: ZCourseId.parse('10'),
            path: 'a1.c10.',
          }),
        ],
      }),
    ]

    const screen = renderAppWithRegistration(reg)(
      <ToolAvailability
        deleteDeployment={vi.fn()}
        editContextControl={vi.fn()}
        accountId={ZAccountId.parse('1')}
        fetchControlsByDeployment={vi.fn().mockResolvedValue(success(deployments))}
        deleteContextControl={vi.fn()}
      />,
    )
    await screen.findByText('Installed in Test Account')
    await screen.findByText('Installed in Course 1')
  })

  it.skip('renders deployments and paginates with Show More', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })
    // Mock fetchControlsByDeployment to simulate pagination
    const fetchControlsByDeployment: FetchControlsByDeployment = vi
      .fn()
      .mockImplementation((options: Parameters<FetchControlsByDeployment>[0]) => {
        if ('registrationId' in options) {
          return Promise.resolve(
            success(page1Deployments, {next: {rel: 'next', url: '/next-page'}}),
          )
        } else {
          return Promise.resolve(success(page2Deployments, {}))
        }
      })
    const utils = renderAppWithRegistration(reg)(
      <ToolAvailability
        deleteDeployment={vi.fn()}
        editContextControl={vi.fn()}
        accountId={ZAccountId.parse('1')}
        fetchControlsByDeployment={fetchControlsByDeployment}
        deleteContextControl={vi.fn()}
      />,
    )

    // Now wait for the main content to appear
    await waitFor(
      () => {
        expect(utils.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
      },
      {timeout: 2000},
    )

    // Assert that context controls from page 1 are shown
    // The root control won't render it's context name.
    expect(utils.queryByText('CC-1-1')).not.toBeInTheDocument()
    expect(utils.getByText('CC-1-2')).toBeInTheDocument()
    expect(utils.getByText('CC-1-3')).toBeInTheDocument()
    expect(utils.getByText('CC-1-4')).toBeInTheDocument()

    // Simulate "Show More" button if present
    const showMore = utils.queryByRole('button', {name: /show more/i})
    if (showMore) {
      fireEvent.click(showMore)
      await waitFor(
        () => {
          expect(utils.getByText('Deployment ID: default-deployment-id-2')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      // Assert that context controls from page 2 are shown
      // the root controls won't render their context name.
      expect(utils.queryByText('CC-2-1')).not.toBeInTheDocument()
      expect(utils.getByText('CC-1-5')).toBeInTheDocument()
      expect(utils.getByText('CC-1-6')).toBeInTheDocument()
      expect(utils.getByText('CC-2-2')).toBeInTheDocument()

      // Ensure no more "Show More" button is present
      expect(utils.queryByRole('button', {name: /show more/i})).not.toBeInTheDocument()
    } else {
      throw new Error('Show More button not found')
    }
  })

  describe('editing exceptions', () => {
    it('lets users edit a sub-account level exception', async () => {
      const mockEdit = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-1'),
            context_name: 'Account 2',
            path: 'a2.',
            account_id: ZAccountId.parse('2'),
            available: false,
            child_control_count: 30,
          }),
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-2'),
            context_name: 'CC-1-2',
            path: 'a2.a3.',
            account_id: ZAccountId.parse('3'),
            available: false,
            course_count: 15,
            subaccount_count: 5,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={mockEdit}
          accountId={ZAccountId.parse('1')}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={vi.fn()}
        />,
      )

      await waitFor(() => {
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
      })

      const control = deployment.context_controls![1]

      fireEvent.click(document.getElementById(`edit-exception-${control.id}`)!)

      expect(await screen.findByText('Edit Exception')).toBeInTheDocument()

      expect(
        screen.getByText(/This change will affect 5 child sub-accounts and 15 child courses/i),
      ).toBeInTheDocument()
      expect(screen.getByText('Exception to be edited:')).toBeInTheDocument()

      expect(screen.getAllByText('Not Available')).toHaveLength(3)

      const selector = screen.getByRole('combobox')
      fireEvent.click(selector)
      fireEvent.click(screen.getByRole('option', {name: 'Available'}))

      fireEvent.click(document.getElementById('update-exception-modal-button')!)

      await waitFor(() => {
        expect(mockEdit).toHaveBeenCalledWith(deployment.registration_id, control.id, true)
        expect(fetchControlsByDeployment).toHaveBeenCalledTimes(2)
      })
    })

    it('lets users close the modal without saving changes', async () => {
      const mockEdit = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-1'),
            context_name: 'Account 2',
            path: 'a2',
            account_id: ZAccountId.parse('2'),
            available: false,
            child_control_count: 30,
          }),
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-2'),
            context_name: 'CC-1-2',
            path: 'a2.a3',
            account_id: ZAccountId.parse('3'),
            available: false,
            course_count: 15,
            subaccount_count: 5,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={mockEdit}
          accountId={ZAccountId.parse('1')}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={vi.fn()}
        />,
      )

      await waitFor(() => {
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
      })

      const control = deployment.context_controls![1]

      fireEvent.click(document.getElementById(`edit-exception-${control.id}`)!)

      expect(await screen.findByText('Edit Exception')).toBeInTheDocument()

      fireEvent.click(screen.getByText('Cancel'))

      await waitFor(() => expect(screen.queryByText('Edit Exception')).not.toBeInTheDocument())

      expect(mockEdit).not.toHaveBeenCalled()
    })

    it('lets users edit a course level exception', async () => {
      const mockEdit = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-1'),
            context_name: 'Account 2',
            path: 'a2.',
            account_id: ZAccountId.parse('2'),
            available: true,
          }),
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-course-1'),
            context_name: 'Test Course 101',
            path: 'a2.c10.',
            course_id: ZCourseId.parse('10'),
            available: false,
            child_control_count: 0,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={mockEdit}
          accountId={ZAccountId.parse('1')}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={vi.fn()}
        />,
      )

      await waitFor(() =>
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument(),
      )

      const control = deployment.context_controls![1]

      fireEvent.click(document.getElementById(`edit-exception-${control.id}`)!)

      expect(await screen.findByText('Edit Exception')).toBeInTheDocument()

      expect(screen.getByText('This change will affect 1 course')).toBeInTheDocument()

      const selector = screen.getByRole('combobox')
      fireEvent.click(selector)
      // Good luck finding something other than get by role to get this
      fireEvent.click(screen.getByRole('option', {name: /^available/i}))

      fireEvent.click(document.getElementById('update-exception-modal-button')!)

      await waitFor(() => {
        expect(mockEdit).toHaveBeenCalledWith(deployment.registration_id, control.id, true)
        expect(fetchControlsByDeployment).toHaveBeenCalledTimes(2)
      })
    })

    it('lets users edit the root level exception', async () => {
      const mockEdit = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })

      const rootControl = mockContextControl({
        id: ZLtiContextControlId.parse('cc-root'),
        context_name: 'Root Account',
        path: 'a1.',
        account_id: ZAccountId.parse('1'),
        available: true,
        child_control_count: 50,
        course_count: 25,
        subaccount_count: 15,
      })

      const deployment = mockDeployment({
        context_name: 'Root Account',
        context_id: '1',
        context_type: 'Account',
        context_controls: [rootControl],
      })

      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={mockEdit}
          accountId={ZAccountId.parse('1')}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={vi.fn()}
        />,
      )

      await waitFor(() =>
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument(),
      )

      fireEvent.click(document.getElementById(`edit-exception-${rootControl.id}`)!)

      expect(await screen.findByText('Edit Exception')).toBeInTheDocument()

      expect(
        screen.getByText(/This change will affect 15 child sub-accounts and 25 child courses/i),
      ).toBeInTheDocument()

      const selector = screen.getByRole('combobox')
      fireEvent.click(selector)
      fireEvent.click(screen.getByRole('option', {name: /^not available/i}))

      fireEvent.click(document.getElementById('update-exception-modal-button')!)

      await waitFor(() => {
        expect(mockEdit).toHaveBeenCalledWith(deployment.registration_id, rootControl.id, false)
        expect(fetchControlsByDeployment).toHaveBeenCalledTimes(2)
      })
    })
  })

  describe('deleting exceptions', () => {
    it('lets users delete a sub-account level exception', async () => {
      const mockDelete = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-1'),
            context_name: 'CC-1-1',
            path: 'a2.',
            account_id: ZAccountId.parse('2'),
            child_control_count: 400,
          }),
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-2'),
            context_name: 'CC-1-2',
            path: 'a2.a3.',
            account_id: ZAccountId.parse('3'),
            child_control_count: 399,
            available: false,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={vi.fn()}
          accountId={ZAccountId.parse('1')}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={mockDelete}
        />,
      )

      await waitFor(() => {
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
      })

      const control = deployment.context_controls![1]

      fireEvent.click(document.getElementById(`delete-exception-${control.id}`)!)

      expect(await screen.findByText(/Exception to be deleted/i)).toBeInTheDocument()

      expect(screen.getAllByText(/Not Available/i)).toHaveLength(2)
      expect(
        screen.getByText(
          /After this change, Test App will be for the cc-1-2 sub-account and its children/i,
        ),
      ).toBeInTheDocument()
      expect(screen.getByText(/399 additional exceptions not shown/i)).toBeInTheDocument()

      fireEvent.click(document.getElementById('delete-exception-modal-button')!)

      await waitFor(() => {
        expect(mockDelete).toHaveBeenCalledWith(deployment.registration_id, control.id)
        expect(fetchControlsByDeployment).toHaveBeenCalledTimes(2)
      })
    })

    it('lets users cancel a sub-account level exception deletion', async () => {
      const mockDelete = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-1'),
            context_name: 'CC-1-1',
            path: 'a2.',
            account_id: ZAccountId.parse('2'),
            child_control_count: 400,
          }),
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-2'),
            context_name: 'CC-1-2',
            path: 'a2.a3.',
            account_id: ZAccountId.parse('3'),
            child_control_count: 399,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={vi.fn()}
          accountId={ZAccountId.parse('1')}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={mockDelete}
        />,
      )

      await waitFor(() =>
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument(),
      )

      const control = deployment.context_controls![1]

      fireEvent.click(document.getElementById(`delete-exception-${control.id}`)!)

      expect(await screen.findByText(/Exception to be deleted/i)).toBeInTheDocument()

      fireEvent.click(screen.getByRole('button', {name: 'Cancel'}))

      await waitFor(() => {
        expect(screen.queryByText(/Exception to be deleted/i)).not.toBeInTheDocument()
      })
    })

    it('lets users delete a course level exception', async () => {
      const mockDelete = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-2'),
            context_name: 'Account 2',
            path: 'a2.',
            account_id: ZAccountId.parse('2'),
            available: true,
          }),
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-course-1'),
            context_name: 'Test Course 101',
            path: 'a2.c10.',
            course_id: ZCourseId.parse('10'),
            available: false,
            child_control_count: 0,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={vi.fn()}
          accountId={ZAccountId.parse('1')}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={mockDelete}
        />,
      )

      // Wait for the main content to appear
      await waitFor(() =>
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument(),
      )

      const control = deployment.context_controls![1]

      fireEvent.click(document.getElementById(`delete-exception-${control.id}`)!)

      expect(await screen.findByText(/exception to be deleted/i)).toBeInTheDocument()

      expect(screen.getByText('Exception to be deleted:')).toBeInTheDocument()
      expect(
        screen.getByText(/After this change, Test App will be for the Test Course 101 course./i),
      ).toBeInTheDocument()
      expect(screen.getAllByText(/not available/i)).toHaveLength(2)
      expect(screen.getByText(/Available/i, {selector: 'strong'})).toBeInTheDocument()

      expect(screen.getByRole('button', {name: 'Cancel'})).toBeInTheDocument()
      const deleteButton = document.getElementById('delete-exception-modal-button')!
      expect(deleteButton).toBeInTheDocument()

      fireEvent.click(deleteButton)
      await waitFor(() => {
        expect(mockDelete).toHaveBeenCalledWith(deployment.registration_id, control.id)
        expect(fetchControlsByDeployment).toHaveBeenCalledTimes(2)
      })
    })

    it('lets users cancel deleting a course level exception deletion', async () => {
      const mockDelete = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-2'),
            context_name: 'Account 2',
            path: 'a2.',
            account_id: ZAccountId.parse('2'),
            available: true,
          }),
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-course-1'),
            context_name: 'Test Course 101',
            path: 'a2.c10.',
            course_id: ZCourseId.parse('10'),
            available: false,
            child_control_count: 0,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={vi.fn()}
          accountId={ZAccountId.parse('1')}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={mockDelete}
        />,
      )

      // Wait for the main content to appear
      await waitFor(
        () => {
          expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      const control = deployment.context_controls![1]

      fireEvent.click(document.getElementById(`delete-exception-${control.id}`)!)

      expect(await screen.findByText(/exception to be deleted/i)).toBeInTheDocument()

      expect(screen.getByText('Exception to be deleted:')).toBeInTheDocument()

      fireEvent.click(screen.getByRole('button', {name: 'Cancel'}))

      await waitFor(() => {
        expect(screen.queryByText(/exception to be deleted/i)).not.toBeInTheDocument()
      })
    })
  })

  describe('deleting deployments', () => {
    it('lets users delete a non-root account level deployment', async () => {
      const mockDelete = vi.fn().mockResolvedValue(success({}))

      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        id: ZLtiDeploymentId.parse('dep-1'),
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        registration_id: ZLtiRegistrationId.parse(reg.id),
        root_account_deployment: false,
        context_controls: [
          mockContextControl({
            // root control
            id: ZLtiContextControlId.parse('cc-1-1'),
            account_id: ZAccountId.parse('2'),
            context_name: 'CC-1-1',
            path: 'a1.a2.',
            available: true,
            course_count: 1,
            subaccount_count: 12,
          }),
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-2'),
            context_name: 'CC-1-2',
            course_id: ZCourseId.parse('10'),
            available: false,
            path: 'a1.a2.c10.',
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={mockDelete}
          editContextControl={vi.fn()}
          accountId={reg.account_id}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={vi.fn()}
        />,
      )

      await waitFor(() => {
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
      })

      fireEvent.click(document.getElementById(`delete-deployment-${deployment.id}`)!)

      expect(screen.getByText('Delete Deployment')).toBeInTheDocument()
      expect(screen.getByText(/\(Deployment ID: default-deployment-id\)/i)).toBeInTheDocument()

      const deleteButton = document.getElementById('delete-deployment-modal-button')
      expect(deleteButton).toBeInTheDocument()

      fireEvent.click(deleteButton!)
      await waitFor(() => {
        expect(mockDelete).toHaveBeenCalledWith({
          registrationId: reg.id,
          accountId: reg.account_id,
          deploymentId: deployment.id,
        })
        expect(fetchControlsByDeployment).toHaveBeenCalledTimes(2)
      })
    })

    it("doesn't let users delete a root account level deployment", async () => {
      const mockDelete = vi.fn().mockResolvedValue(success({}))
      const reg = mockRegistrationWithAllInformation({n: 'Test App', i: 1})
      const deployment = mockDeployment({
        id: ZLtiDeploymentId.parse('dep-root-1'),
        context_name: 'Root Account',
        context_id: reg.account_id,
        context_type: 'Account',
        registration_id: ZLtiRegistrationId.parse(reg.id),
        root_account_deployment: true,
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-root-1'),
            account_id: reg.account_id,
            context_name: 'Root Account',
            path: `a${reg.account_id}.`,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={mockDelete}
          editContextControl={vi.fn()}
          accountId={reg.account_id}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={vi.fn()}
        />,
      )
      await waitFor(() => {
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
      })
      expect(document.getElementById(`delete-deployment-${deployment.id}`)).not.toBeInTheDocument()
    })

    it('lets users cancel deleting a deployment', async () => {
      const mockDelete = vi.fn().mockResolvedValue(success({}))
      const reg = mockRegistrationWithAllInformation({n: 'Test App', i: 1})
      const deployment = mockDeployment({
        id: ZLtiDeploymentId.parse('dep-1'),
        context_name: 'Test Account',
        context_id: '2',
        context_type: 'Account',
        registration_id: ZLtiRegistrationId.parse(reg.id),
        root_account_deployment: false,
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-1-1'),
            account_id: ZAccountId.parse('2'),
            context_name: 'CC-1-1',
            path: 'a1.a2.',
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={mockDelete}
          editContextControl={vi.fn()}
          accountId={reg.account_id}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={vi.fn()}
        />,
      )
      await waitFor(() => {
        expect(screen.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
      })
      fireEvent.click(document.getElementById('delete-deployment-dep-1')!)
      expect(screen.getByText('Delete Deployment')).toBeInTheDocument()
      fireEvent.click(screen.getByRole('button', {name: 'Cancel'}))
      await waitFor(() => {
        expect(screen.queryByText('Delete Deployment')).not.toBeInTheDocument()
      })
    })
  })

  describe('adding exceptions', () => {
    it('does not allow adding exceptions for course deployments', async () => {
      const reg = mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      })
      const deployment = mockDeployment({
        id: ZLtiDeploymentId.parse('dep-course-1'),
        context_name: 'Test Course',
        context_id: '10',
        context_type: 'Course',
        registration_id: ZLtiRegistrationId.parse(reg.id),
        context_controls: [
          mockContextControl({
            id: ZLtiContextControlId.parse('cc-course-1'),
            context_name: 'Test Course 101',
            path: 'a10.c101.',
            course_id: ZCourseId.parse('10'),
            available: true,
          }),
        ],
      })
      const fetchControlsByDeployment = vi.fn().mockResolvedValue(success([deployment]))
      const utils = renderAppWithRegistration(reg)(
        <ToolAvailability
          deleteDeployment={vi.fn()}
          editContextControl={vi.fn()}
          accountId={reg.account_id}
          fetchControlsByDeployment={fetchControlsByDeployment}
          deleteContextControl={vi.fn()}
        />,
      )

      await waitFor(() => {
        expect(utils.getByText('Deployment ID: default-deployment-id')).toBeInTheDocument()
      })

      // Assert that the "Add Exception" button is not present for course deployments
      expect(utils.queryByRole('button', {name: /add exception/i})).not.toBeInTheDocument()
    })
  })
})
