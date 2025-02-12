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
import {render, screen, waitFor, cleanup} from '@testing-library/react'
import {ZAccountId} from '../../model/AccountId'
import {ZDeveloperKeyId} from '../../model/developer_key/DeveloperKeyId'
import {InheritedKeyRegistrationWizard} from '../InheritedKeyRegistrationWizard'
import {
  openInheritedKeyWizard,
  useInheritedKeyWizardState,
} from '../InheritedKeyRegistrationWizardState'
import type {InheritedKeyService} from '../InheritedKeyService'
import {success} from '../../../common/lib/apiResult/ApiResult'
import {mockRegistration} from '../../pages/manage/__tests__/helpers'
import userEvent from '@testing-library/user-event'

describe('RegistrationWizardModal', () => {
  let error: (...data: any[]) => void
  let warn: (...data: any[]) => void

  beforeAll(() => {
    // instui logs an error when we render a component
    // immediately under Modal

    error = console.error

    warn = console.warn

    console.error = jest.fn()

    console.warn = jest.fn()
  })

  afterAll(() => {
    console.error = error

    console.warn = warn
  })

  const bindGlobalLtiRegistration = jest.fn()
  const fetchRegistrationByClientId = jest.fn()

  const inheritedKeyService: InheritedKeyService = {
    bindGlobalLtiRegistration,
    fetchRegistrationByClientId,
  }

  describe('When opened', () => {
    const accountId = ZAccountId.parse('123')
    const developerKeyId = ZDeveloperKeyId.parse('abc')
    const onSuccessfulInstallation = jest.fn()

    beforeEach(() => {
      openInheritedKeyWizard(developerKeyId, onSuccessfulInstallation)
      bindGlobalLtiRegistration.mockClear()
      fetchRegistrationByClientId.mockClear()
    })

    afterEach(() => {
      useInheritedKeyWizardState.getState().close()
      cleanup()
    })

    it('should render the modal title', () => {
      fetchRegistrationByClientId.mockResolvedValue(success(mockRegistration('An Example App', 1)))
      render(<InheritedKeyRegistrationWizard accountId={accountId} service={inheritedKeyService} />)
      const headerText = screen.getByRole('heading', {
        name: /Install App/i,
      })
      expect(headerText).toBeInTheDocument()
    })

    it('should request the registration', async () => {
      fetchRegistrationByClientId.mockResolvedValue(
        success(
          mockRegistration('An Example App', 2, {
            description: 'An Example App',
            placements: [
              {
                placement: 'course_navigation',
                message_type: 'LtiResourceLinkRequest',
                text: 'An_Example_App',
              },
            ],
          }),
        ),
      )
      render(<InheritedKeyRegistrationWizard accountId={accountId} service={inheritedKeyService} />)
      const headerText = screen.getByRole('heading', {
        name: /Install App/i,
      })
      expect(headerText).toBeInTheDocument()
      await waitFor(() => screen.getByText(/An_Example_App/i))
      expect(fetchRegistrationByClientId).toHaveBeenCalledWith(accountId, developerKeyId)
    })

    it('should disable the next button while the registration is loading', () => {
      fetchRegistrationByClientId.mockReturnValue(new Promise(() => {}))
      render(<InheritedKeyRegistrationWizard accountId={accountId} service={inheritedKeyService} />)
      const installButton = screen.getByRole('button', {
        name: /Install App/i,
      })
      expect(installButton).toBeInTheDocument()
      expect(installButton).toBeDisabled()
    })

    it('should enable the install button when the registration loads', async () => {
      fetchRegistrationByClientId.mockResolvedValue(
        success(
          mockRegistration('An Example App', 2, {
            description: 'An Example App',
            placements: [
              {
                placement: 'course_navigation',
                message_type: 'LtiResourceLinkRequest',
                text: 'An_Example_App',
              },
            ],
          }),
        ),
      )
      render(<InheritedKeyRegistrationWizard accountId={accountId} service={inheritedKeyService} />)
      const installButton = screen.getByRole('button', {
        name: /Install App/i,
      })
      expect(installButton).toBeInTheDocument()
      await waitFor(() => expect(installButton).toBeEnabled())
    })

    it('should call the onSuccessfulInstallation callback when the registration is installed', async () => {
      fetchRegistrationByClientId.mockResolvedValue(
        success(
          mockRegistration('An Example App', 2, {
            description: 'An Example App',
            placements: [
              {
                placement: 'course_navigation',
                message_type: 'LtiResourceLinkRequest',
                text: 'An_Example_App',
              },
            ],
          }),
        ),
      )
      bindGlobalLtiRegistration.mockResolvedValue(success({}))
      render(<InheritedKeyRegistrationWizard accountId={accountId} service={inheritedKeyService} />)
      const installButton = screen.getByRole('button', {
        name: /Install App/i,
      })
      expect(installButton).toBeInTheDocument()
      await waitFor(() => expect(installButton).toBeEnabled())
      await userEvent.click(installButton)
      await waitFor(() => expect(onSuccessfulInstallation).toHaveBeenCalled())
    })
  })
})
