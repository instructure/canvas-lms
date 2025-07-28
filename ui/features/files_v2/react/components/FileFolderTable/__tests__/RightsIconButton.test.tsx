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
import RightsIconButton from '../RightsIconButton'

let defaultProps: any
describe('RightsIconButton', () => {
  beforeEach(() => {
    defaultProps = {
      usageRights: null,
      userCanEditFilesForContext: true,
    }
  })

  it('renders nothing when user cannot edit and usage rights is not set', () => {
    defaultProps.userCanEditFilesForContext = false
    const {container} = render(<RightsIconButton {...defaultProps} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('renders warning icon when usage rights is not set', () => {
    render(<RightsIconButton {...defaultProps} />)
    expect(
      screen.getAllByText('Before publishing this file, you must specify usage rights'),
    ).toHaveLength(2)
  })

  it('renders own copyright icon', () => {
    defaultProps.usageRights = {
      use_justification: 'own_copyright',
      license_name: 'License',
    }

    render(<RightsIconButton {...defaultProps} />)

    expect(screen.getByText(defaultProps.usageRights.license_name)).toBeInTheDocument()
    expect(screen.getByText('Own Copyright')).toBeInTheDocument()
  })

  it('renders public domain icon', () => {
    defaultProps.usageRights = {
      use_justification: 'public_domain',
      license_name: 'License',
    }

    render(<RightsIconButton {...defaultProps} />)

    expect(screen.getByText(defaultProps.usageRights.license_name)).toBeInTheDocument()
    expect(screen.getByText('Public Domain')).toBeInTheDocument()
  })

  it('renders used by permission icon', () => {
    defaultProps.usageRights = {
      use_justification: 'used_by_permission',
      license_name: 'License',
    }

    render(<RightsIconButton {...defaultProps} />)

    expect(screen.getByText(defaultProps.usageRights.license_name)).toBeInTheDocument()
    expect(screen.getByText('Used by Permission')).toBeInTheDocument()
  })

  it('renders fair use icon', () => {
    defaultProps.usageRights = {
      use_justification: 'fair_use',
      license_name: 'License',
    }

    render(<RightsIconButton {...defaultProps} />)

    expect(screen.getByText(defaultProps.usageRights.license_name)).toBeInTheDocument()
    expect(screen.getByText('Fair Use')).toBeInTheDocument()
  })

  it('renders creative commons icon', () => {
    defaultProps.usageRights = {
      use_justification: 'creative_commons',
      license_name: 'License',
    }

    render(<RightsIconButton {...defaultProps} />)

    expect(screen.getByText(defaultProps.usageRights.license_name)).toBeInTheDocument()
    expect(screen.getByText('Creative Commons')).toBeInTheDocument()
  })

  it('renders nothing when usage rights licence is invalid', () => {
    defaultProps.usageRights = {
      use_justification: 'test _invalid_license',
      license_name: 'This is an invalid license',
    }

    const {container} = render(<RightsIconButton {...defaultProps} />)
    expect(container).toBeEmptyDOMElement()
  })
})
