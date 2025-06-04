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

import {ZAccountId} from '@canvas/lti-apps/models/AccountId'
import {success} from '../../../../common/lib/apiResult/ApiResult'
import {ZLtiDeploymentId} from '../../../model/LtiDeploymentId'
import {ZLtiRegistrationId} from '../../../model/LtiRegistrationId'
import {mockDeployment, mockRegistrationWithAllInformation} from '../../manage/__tests__/helpers'
import {ToolAvailability} from '../availability/ToolAvailability'
import {renderAppWithRegistration} from '../configuration/__tests__/helpers'

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
      mockDeployment({}),
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
})
