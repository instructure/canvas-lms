/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import React from 'react'
import AdminConsentLink from '../components/AdminConsentLink'

describe('AdminConsentLink', () => {
  const props = overrides => ({
    enabled: true,
    baseUrl: 'https://www.microsoft.com',
    clientId: '2345-2345-23452-qefqewr',
    redirectUri: 'https://www.instructure.com/',
    tenant: 'canvas.onmicrosoft.com',
    ...overrides,
  })
  const subject = overrides => render(<AdminConsentLink {...props(overrides)} />)

  it('renders an message', () => {
    expect(subject().getByText(/After completing the above configuration/)).toBeInTheDocument()
  })

  it('renders a valid Microsoft admin consent link', () => {
    const anchorTag = subject().getByText(/Grant tenant access/)
    expect(anchorTag.href).toEqual(
      'https://www.microsoft.com/canvas.onmicrosoft.com/adminconsent?client_id=2345-2345-23452-qefqewr&redirect_uri=https%3A%2F%2Fwww.instructure.com%2F'
    )
  })

  describe('when "enabled" is falsey', () => {
    const overrides = {enabled: false}

    it('does not render a message and link', () => {
      expect(
        subject(overrides).queryByText(/After completing the above configuration/)
      ).not.toBeInTheDocument()
    })
  })
})
