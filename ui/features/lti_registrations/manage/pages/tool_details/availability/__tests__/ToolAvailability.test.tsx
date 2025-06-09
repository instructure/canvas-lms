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

import {fireEvent, waitFor} from '@testing-library/react'
import {success} from '../../../../../common/lib/apiResult/ApiResult'
import {FetchControlsByDeployment} from '../../../../api/contextControls'
import {ZAccountId} from '../../../../model/AccountId'
import {ZLtiContextControlId} from '../../../../model/LtiContextControl'
import {ZLtiDeploymentId} from '../../../../model/LtiDeploymentId'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'
import {mockRegistrationWithAllInformation} from '../../../manage/__tests__/helpers'
import {renderAppWithRegistration} from '../../configuration/__tests__/helpers'
import {ToolAvailability} from '../ToolAvailability'
import {mockContextControl, mockDeployment} from './helpers'

const page1Deployments = [
  mockDeployment({
    id: ZLtiDeploymentId.parse('dep-1'),
    context_controls: [
      mockContextControl({id: ZLtiContextControlId.parse('cc-1-1'), context_name: 'CC-1-1'}),
      mockContextControl({id: ZLtiContextControlId.parse('cc-1-2'), context_name: 'CC-1-2'}),
      mockContextControl({id: ZLtiContextControlId.parse('cc-1-3'), context_name: 'CC-1-3'}),
      mockContextControl({id: ZLtiContextControlId.parse('cc-1-4'), context_name: 'CC-1-4'}),
    ],
  }),
]
const page2Deployments = [
  mockDeployment({
    id: ZLtiDeploymentId.parse('dep-1'),
    context_controls: [
      mockContextControl({id: ZLtiContextControlId.parse('cc-1-5'), context_name: 'CC-1-5'}),
      mockContextControl({id: ZLtiContextControlId.parse('cc-1-6'), context_name: 'CC-1-6'}),
    ],
  }),
  mockDeployment({
    id: ZLtiDeploymentId.parse('dep-2'),
    deployment_id: ZLtiDeploymentId.parse('default-deployment-id-2'),
    context_controls: [
      mockContextControl({id: ZLtiContextControlId.parse('cc-2-1'), context_name: 'CC-2-1'}),
      mockContextControl({id: ZLtiContextControlId.parse('cc-2-2'), context_name: 'CC-2-2'}),
    ],
  }),
]

describe('ToolAvailability', () => {
  it('renders the header text', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })
    const fetchControlsByDeployment = jest.fn().mockResolvedValue(success([]))
    const accountId = ZAccountId.parse('1')
    const screen = renderAppWithRegistration(reg)(
      <ToolAvailability
        accountId={accountId}
        fetchControlsByDeployment={fetchControlsByDeployment}
      />,
    )
    expect(fetchControlsByDeployment).toHaveBeenCalled()

    await screen.findByText(/Control Test App's availability/)
    expect(
      screen.queryByText('This tool has not been deployed to any sub-accounts or courses.'),
    ).toBeInTheDocument()
  })

  it('renders all deployments', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })
    const deployments = [
      mockDeployment({
        context_name: 'Test Account',
      }),
      mockDeployment({
        id: ZLtiDeploymentId.parse('2'),
        context_type: 'Course',
        context_name: 'Course 1',
        registration_id: ZLtiRegistrationId.parse('1'),
      }),
    ]

    const screen = renderAppWithRegistration(reg)(
      <ToolAvailability
        accountId={ZAccountId.parse('1')}
        fetchControlsByDeployment={jest.fn().mockResolvedValue(success(deployments))}
      />,
    )
    await screen.findByText('Installed in Test Account')
    await screen.findByText('Installed in Course 1')
  })

  it('renders deployments and paginates with Show More', async () => {
    const reg = mockRegistrationWithAllInformation({
      n: 'Test App',
      i: 1,
    })
    // Mock fetchControlsByDeployment to simulate pagination
    const fetchControlsByDeployment: FetchControlsByDeployment = jest
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
        accountId={ZAccountId.parse('1')}
        fetchControlsByDeployment={fetchControlsByDeployment}
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
    expect(utils.getByText('CC-1-1')).toBeInTheDocument()
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
      expect(utils.getByText('CC-1-5')).toBeInTheDocument()
      expect(utils.getByText('CC-1-6')).toBeInTheDocument()
      expect(utils.getByText('CC-2-1')).toBeInTheDocument()
      expect(utils.getByText('CC-2-2')).toBeInTheDocument()

      // Ensure no more "Show More" button is present
      expect(utils.queryByRole('button', {name: /show more/i})).not.toBeInTheDocument()
    } else {
      throw new Error('Show More button not found')
    }
  })
})
