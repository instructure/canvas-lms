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
import {mockRegistration} from '../../pages/manage/__tests__/helpers'
import {mockInternalConfiguration} from './helpers'
import {mockLti1p3RegistrationWizardService} from '../../dynamic_registration_wizard/__tests__/helpers'
import {ZAccountId} from '../../model/AccountId'
import {LtiScopes} from '@canvas/lti/model/LtiScope'
import {LtiPlacements} from '../../model/LtiPlacement'
import {success} from '../../../common/lib/apiResult/ApiResult'
import {ZLtiRegistrationId} from '../../model/LtiRegistrationId'

// NOTE: The registration wizard creates it's own store during render, so testing it is currently
// quite slow. Hopefully, we can refactor it to make testing easier in the future, but for now,
// we'll just test a simple happy path and some error cases.
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

  it('calls onDismiss when the user clicks the X button', async () => {
    const onDismiss = vi.fn()
    render(<Lti1p3RegistrationWizard {...defaultProps} onDismiss={onDismiss} />)

    const closeButton = await screen.findByRole('button', {
      name: 'Close',
    })
    await userEvent.click(closeButton)

    expect(onDismiss).toHaveBeenCalled()
  })

  it('navigates through all steps in order', async () => {
    render(<Lti1p3RegistrationWizard {...defaultProps} />)

    expect(screen.getByText('LTI 1.3 Registration')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(screen.getByText('Permissions')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(screen.getByText('Data Sharing')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(screen.getByText('Placements')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(screen.getByText('Override URIs')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(screen.getByText('Nickname')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(screen.getByText('Placement Icon URLs')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(screen.getByText('Review')).toBeInTheDocument()
  })

  it('allows navigating back through steps', async () => {
    render(<Lti1p3RegistrationWizard {...defaultProps} />)

    await userEvent.click(findNextButton())
    expect(screen.getByText('Permissions')).toBeInTheDocument()

    await userEvent.click(screen.getByText('Previous').closest('button')!)
    expect(screen.getByText('LTI 1.3 Registration')).toBeInTheDocument()
  })

  it('shows updating state when updating an existing registration', async () => {
    const existingRegistration = mockRegistration('Test App', 1)
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        service={mockLti1p3RegistrationWizardService({
          updateLtiRegistration: vi.fn().mockImplementation(() => new Promise(() => {})),
        })}
        existingRegistration={existingRegistration}
      />,
    )

    // Annoyingly, we have to go through all of the steps, for now.
    for (let i = 0; i < 7; i++) {
      await userEvent.click(findNextButton())
    }
    await userEvent.click(screen.getByText('Update App').closest('button')!)
    expect(screen.getAllByText('Updating App')[0]).toBeInTheDocument()
  })

  it('shows error state when an error occurs', async () => {
    const existingRegistration = mockRegistration('Test App', 1)
    const errorService = mockLti1p3RegistrationWizardService({
      updateLtiRegistration: vi.fn().mockReturnValue({
        _type: 'GenericError',
        message: 'Test error',
      }),
    })
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        service={errorService}
        existingRegistration={existingRegistration}
      />,
    )

    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())

    await userEvent.click(screen.getByText('Update App').closest('button')!)

    expect(screen.getByText(/sorry, something broke/i)).toBeInTheDocument()
  })

  it("doesn't skip the icon confirmation screen even if the tool has no placements with icons", async () => {
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        internalConfiguration={mockInternalConfiguration({
          placements: [{placement: 'course_navigation'}],
        })}
      />,
    )
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    expect(screen.getByText(/Tool Icon URL/i, {selector: 'h3'})).toBeInTheDocument()
    await userEvent.click(findNextButton())
    expect(screen.getByText(/^Review$/i)).toBeInTheDocument()

    await userEvent.click(screen.getByText(/^Previous$/i).closest('button')!)
    expect(screen.getByText(/Tool Icon URL/i, {selector: 'h3'})).toBeInTheDocument()
  })

  it('includes EULA Settings step when tool has EulaUser scope and asset processor placements', async () => {
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        internalConfiguration={mockInternalConfiguration({
          scopes: [LtiScopes.EulaUser],
          placements: [
            {
              placement: LtiPlacements.ActivityAssetProcessor,
              enabled: true,
              text: 'Activity Asset Processor',
            },
          ],
        })}
      />,
    )

    await userEvent.click(findNextButton())
    expect(await screen.findByText('Permissions')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(await screen.findByText('Data Sharing')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(await screen.findByText('Placements')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(await screen.findByText('EULA Settings')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(await screen.findByText('Override URIs')).toBeInTheDocument()
  }, 10000)

  it('skips EULA Settings step when tool lacks EulaUser scope', async () => {
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        internalConfiguration={mockInternalConfiguration({
          scopes: ['https://canvas.instructure.com/lti-ags/progress/scope/show'],
          placements: [
            {
              placement: LtiPlacements.ActivityAssetProcessor,
              enabled: true,
              text: 'Activity Asset Processor',
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
    expect(screen.queryByText('EULA Settings')).not.toBeInTheDocument()
  })

  it('skips EULA Settings step when tool lacks asset processor placements', async () => {
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        internalConfiguration={mockInternalConfiguration({
          scopes: [LtiScopes.EulaUser],
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
    expect(screen.queryByText('EULA Settings')).not.toBeInTheDocument()
  })

  it('includes EULA Settings step when tool has existing LtiEulaRequest message settings', async () => {
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        internalConfiguration={mockInternalConfiguration({
          launch_settings: {
            message_settings: [
              {
                type: 'LtiEulaRequest',
                enabled: true,
                target_link_uri: 'https://example.com/eula',
                custom_fields: {
                  eula_field1: 'value1',
                },
              },
            ],
          },
        })}
      />,
    )

    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())

    await userEvent.click(findNextButton())
    expect(screen.getByText('EULA Settings')).toBeInTheDocument()

    await userEvent.click(findNextButton())
    expect(screen.getByText('Override URIs')).toBeInTheDocument()
  })

  it('correctly navigates back from EULA Settings step', async () => {
    render(
      <Lti1p3RegistrationWizard
        {...defaultProps}
        internalConfiguration={mockInternalConfiguration({
          scopes: [LtiScopes.EulaUser],
          placements: [
            {
              placement: LtiPlacements.ActivityAssetProcessor,
              enabled: true,
              text: 'Activity Asset Processor',
            },
          ],
        })}
      />,
    )

    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())
    await userEvent.click(findNextButton())

    expect(screen.getByText('EULA Settings')).toBeInTheDocument()

    await userEvent.click(screen.getByText('Previous').closest('button')!)
    expect(screen.getByText('Placements')).toBeInTheDocument()
  })

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

  it('focuses invalid inputs if any fields are invalid on launch settings step', async () => {
    const user = userEvent.setup()
    render(<Lti1p3RegistrationWizard {...defaultProps} />)

    const redirectURIs = screen.getByLabelText(/Redirect URIs/i)
    await user.clear(redirectURIs)
    await user.paste('http:<<<>>')
    await user.tab()
    await user.click(findNextButton())
    expect(redirectURIs).toHaveFocus()

    await user.clear(redirectURIs)
    await user.paste('https://example.com/launch')

    const domain = screen.getByLabelText('Domain')
    await user.clear(domain)
    await user.paste('domain00---.com.')
    await user.tab()
    await user.click(findNextButton())
    expect(domain).toHaveFocus()

    await user.clear(domain)
    await user.paste('example.com')
    await user.click(findNextButton())
    expect(screen.getByText('Permissions')).toBeInTheDocument()
  })

  it('focuses invalid inputs if any fields are invalid on override uris step', async () => {
    const user = userEvent.setup()
    render(<Lti1p3RegistrationWizard {...defaultProps} />)

    // Navigate to Override URIs step
    await user.click(findNextButton()) // Launch Settings -> Permissions
    await user.click(findNextButton()) // Permissions -> Data Sharing
    await user.click(findNextButton()) // Data Sharing -> Placements
    await user.click(findNextButton()) // Placements -> Override URIs

    expect(screen.getByText('Override URIs')).toBeInTheDocument()

    // Enter an invalid override URI for course_navigation placement (first one)
    const overrideUriInputs = screen.getAllByLabelText('Override URI')
    const overrideUriInput = overrideUriInputs[0]
    await user.clear(overrideUriInput)
    await user.paste('invalid-url')
    await user.tab()
    await user.click(findNextButton())
    expect(overrideUriInput).toHaveFocus()

    // Fix the invalid URI and verify the wizard can proceed
    await user.clear(overrideUriInput)
    await user.paste('https://example.com/override')
    await user.click(findNextButton())
    expect(screen.getByText('Nickname')).toBeInTheDocument()
  })

  it('focuses invalid inputs if any fields are invalid on icon urls step', async () => {
    const user = userEvent.setup()
    render(<Lti1p3RegistrationWizard {...defaultProps} />)

    await user.click(findNextButton())
    await user.click(findNextButton())
    await user.click(findNextButton())
    await user.click(findNextButton())
    await user.click(findNextButton())
    await user.click(findNextButton())

    expect(screen.getByText('Placement Icon URLs')).toBeInTheDocument()

    // Enter an invalid icon URL for global_navigation placement (which supports icons)
    // Find the Global Navigation heading first, then find the input associated with it
    screen.getByText('Global Navigation')
    const iconUrlInput = screen.getAllByRole('textbox')[1]
    await user.clear(iconUrlInput)
    await user.paste('invalid-url')
    await user.tab()
    await user.click(findNextButton())
    expect(iconUrlInput).toHaveFocus()

    // Fix the invalid URL and verify the wizard can proceed
    await user.clear(iconUrlInput)
    await user.paste('https://example.com/icon.png')
    await user.click(findNextButton())
    expect(screen.getByText('Review')).toBeInTheDocument()
  })
})
