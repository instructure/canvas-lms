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

import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Lti1p3RegistrationWizard} from '../Lti1p3RegistrationWizard'
import {mockInternalConfiguration} from './helpers'
import {mockLti1p3RegistrationWizardService} from '../../dynamic_registration_wizard/__tests__/helpers'
import {ZAccountId} from '../../model/AccountId'

describe('Lti1p3RegistrationWizard', () => {
  afterEach(() => {
    cleanup()
  })

  const accountId = ZAccountId.parse('123')
  const defaultProps = {
    accountId,
    internalConfiguration: mockInternalConfiguration(),
    service: mockLti1p3RegistrationWizardService({}),
    onDismiss: vi.fn(),
    onSuccessfulRegistration: vi.fn(),
  }

  const findNextButton = () => screen.getByText('Next').closest('button')!

  it('correctly skips EULA Settings when navigating back if not applicable', async () => {
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        internalConfiguration={mockInternalConfiguration({
          scopes: ['https://canvas.instructure.com/lti-ags/progress/scope/show'],
          placements: [
            {
              placement: 'course_navigation',
              enabled: true,
              text: 'Course Navigation',
            },
          ],
        })}
      />,
    )

    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())

    expect(screen.getByText('Override URIs')).toBeInTheDocument()

    await userEvent.click(screen.getByText('Previous').closest('button')!)
    expect(screen.getByText('Placements')).toBeInTheDocument()
    expect(screen.queryByText('EULA Settings')).not.toBeInTheDocument()
  })
})
