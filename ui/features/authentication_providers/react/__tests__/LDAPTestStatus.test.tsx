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
import LDAPTestStatus from '../ldap/LDAPTestStatus'
import {TestStatus} from '../ldap/types'

describe('LDAPTestStatus', () => {
  it('should render the title', () => {
    const title = 'Test Title'
    render(<LDAPTestStatus title={title} status={TestStatus.IDLE} />)

    expect(screen.getByText(title)).toBeInTheDocument()
  })

  it('should show the loading spinner when status is loading', () => {
    render(<LDAPTestStatus title="Loading Test" status={TestStatus.LOADING} />)

    expect(screen.getByLabelText('Loading ldap test')).toBeInTheDocument()
  })

  it('should show success pill when status is succeed', () => {
    render(<LDAPTestStatus title="Success Test" status={TestStatus.SUCCEED} />)

    expect(screen.getByText('OK')).toBeInTheDocument()
  })

  it('should show failed pill when status is failed', () => {
    render(<LDAPTestStatus title="Failed Test" status={TestStatus.FAILED} />)

    expect(screen.getByText('Failed')).toBeInTheDocument()
  })

  it('should show canceled pill when status is canceled', () => {
    render(<LDAPTestStatus title="Canceled Test" status={TestStatus.CANCELED} />)

    expect(screen.getByText('Canceled')).toBeInTheDocument()
  })

  it('should not render anything when status is idle', () => {
    render(<LDAPTestStatus title="Idle Test" status={TestStatus.IDLE} />)

    expect(screen.queryByText('Idle Test')).toBeInTheDocument()
    expect(screen.queryByText('Loading ldap test')).not.toBeInTheDocument()
    expect(screen.queryByText('OK')).not.toBeInTheDocument()
    expect(screen.queryByText('Failed')).not.toBeInTheDocument()
    expect(screen.queryByText('Canceled')).not.toBeInTheDocument()
  })
})
