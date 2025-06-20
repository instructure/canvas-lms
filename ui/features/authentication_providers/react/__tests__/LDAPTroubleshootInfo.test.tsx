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

import {render, screen} from '@testing-library/react'
import LDAPTroubleshootInfo, {LDAPTroubleshootInfoProps} from '../ldap/LDAPTroubleshootInfo'

describe('LDAPTroubleshootInfo', () => {
  const info: LDAPTroubleshootInfoProps['info'] = {
    title: 'Troubleshooting LDAP',
    description: 'Check your LDAP server settings.',
    hints: ['Ensure your LDAP server is reachable.', 'Verify your LDAP credentials.'],
  }

  it('should render the troubleshooting information', () => {
    const props: LDAPTroubleshootInfoProps = {
      info,
      error: null,
    }
    render(<LDAPTroubleshootInfo {...props} />)

    expect(screen.getByText(props.info.title)).toBeInTheDocument()
    expect(screen.getByText(props.info.description)).toBeInTheDocument()
    props.info.hints.forEach(hint => {
      expect(screen.getByText(hint)).toBeInTheDocument()
    })
  })

  it('should display an error message if error is provided', () => {
    const props = {
      info,
      error: 'Connection failed',
    } satisfies LDAPTroubleshootInfoProps
    render(<LDAPTroubleshootInfo {...props} />)

    expect(screen.getByText(props.error)).toBeInTheDocument()
  })
})
