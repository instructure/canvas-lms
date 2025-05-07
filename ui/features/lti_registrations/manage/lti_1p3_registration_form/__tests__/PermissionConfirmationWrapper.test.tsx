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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {PermissionConfirmationWrapper} from '../components/PermissionConfirmationWrapper'
import {mockInternalConfiguration} from './helpers'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {LtiScopes} from '@canvas/lti/model/LtiScope'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'

describe('PermissionConfirmationWrapper', () => {
  beforeEach(() => {
    userEvent.setup()
  })

  it('renders the component', () => {
    const internalConfig = mockInternalConfiguration({title: 'Test App'})
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    render(
      <PermissionConfirmationWrapper
        internalConfig={internalConfig}
        overlayStore={overlayStore}
        showAllSettings={true}
      />,
    )

    expect(screen.getByText('Permissions')).toBeInTheDocument()
    expect(
      screen.getByText(/is requesting permission to perform the following actions/i),
    ).toBeInTheDocument()
  })

  it('renders a checkbox for all scopes, with only the default checkboxes toggled on', () => {
    const internalConfig = mockInternalConfiguration({
      scopes: [LtiScopes.AgsLineItem, LtiScopes.AgsScore],
    })
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    render(
      <PermissionConfirmationWrapper
        internalConfig={internalConfig}
        overlayStore={overlayStore}
        showAllSettings={true}
      />,
    )

    expect(screen.getAllByRole('checkbox')).toHaveLength(Object.values(LtiScopes).length)

    expect(screen.getByLabelText(i18nLtiScope(LtiScopes.AgsLineItem))).toBeChecked()
    expect(screen.getByLabelText(i18nLtiScope(LtiScopes.AgsScore))).toBeChecked()
  })

  it('toggles the scope when a checkbox is clicked', async () => {
    const internalConfig = mockInternalConfiguration({scopes: [LtiScopes.AgsLineItem]})
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    render(
      <PermissionConfirmationWrapper
        internalConfig={internalConfig}
        overlayStore={overlayStore}
        showAllSettings={true}
      />,
    )

    const firstScope = screen.getByLabelText(i18nLtiScope(LtiScopes.AgsLineItem))
    expect(firstScope).toBeChecked()

    await userEvent.click(firstScope)
    expect(firstScope).not.toBeChecked()

    await userEvent.click(firstScope)
    expect(firstScope).toBeChecked()
  })
})
