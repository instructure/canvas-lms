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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {PermissionConfirmationWrapper} from '../components/PermissionConfirmationWrapper'
import {mockRegistration, mockToolConfiguration} from './helpers'
import {LtiScopes} from '@canvas/lti/model/LtiScope'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {createDynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'

describe('PermissionConfirmationWrapper', () => {
  const registration = mockRegistration({
    name: 'Test App',
    configuration: mockToolConfiguration({
      scopes: [LtiScopes.AgsLineItem, LtiScopes.AgsLineItemReadonly, LtiScopes.AgsResultReadonly],
    }),
  })

  const overlayStore = createDynamicRegistrationOverlayStore(registration.name, registration)

  it('renders the PermissionConfirmation component with the correct props', () => {
    render(
      <PermissionConfirmationWrapper registration={registration} overlayStore={overlayStore} />,
    )

    expect(screen.getByText('Permissions')).toBeInTheDocument()
    expect(
      screen.getByText(/is requesting permission to perform the following actions/i),
    ).toBeInTheDocument()

    registration.configuration.scopes.forEach(s => {
      const scope = i18nLtiScope(s)
      expect(screen.getByText(scope)).toBeInTheDocument()
    })
  })

  it('toggles the scope when a checkbox is clicked', async () => {
    render(
      <PermissionConfirmationWrapper registration={registration} overlayStore={overlayStore} />,
    )

    const lineItemCheckbox = screen.getByLabelText(i18nLtiScope(LtiScopes.AgsLineItem))
    const lineItemReadonlyCheckbox = screen.getByLabelText(
      i18nLtiScope(LtiScopes.AgsLineItemReadonly),
    )
    const resultReadonlyCheckbox = screen.getByLabelText(i18nLtiScope(LtiScopes.AgsResultReadonly))

    expect(lineItemCheckbox).toBeChecked()
    expect(lineItemReadonlyCheckbox).toBeChecked()
    expect(resultReadonlyCheckbox).toBeChecked()

    await userEvent.click(lineItemReadonlyCheckbox)
    expect(lineItemReadonlyCheckbox).not.toBeChecked()

    await userEvent.click(lineItemCheckbox)
    expect(lineItemCheckbox).not.toBeChecked()

    await userEvent.click(resultReadonlyCheckbox)
    expect(resultReadonlyCheckbox).not.toBeChecked()
  })

  it('renders an appropriate message if no scopes are requested', async () => {
    render(
      <PermissionConfirmationWrapper
        registration={mockRegistration({
          configuration: mockToolConfiguration({scopes: []}),
        })}
        overlayStore={overlayStore}
      />,
    )

    expect(screen.getByText('Permissions')).toBeInTheDocument()

    expect(screen.getByText(/hasn't requested any permissions/)).toBeInTheDocument()
  })
})
