/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import CollaborationsNavigation from '../CollaborationsNavigation'
import fakeENV from '@canvas/test-utils/fakeENV'

const defaultProps = {
  ltiCollaborators: {
    ltiCollaboratorsData: [{name: 'A name', id: '1'}],
  },
}

describe('CollaborationsNavigation', () => {
  beforeEach(() => {
    fakeENV.setup({
      context_asset_string: 'courses_1',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders the collaborations title', () => {
    const {getByTestId} = render(<CollaborationsNavigation {...defaultProps} />)
    expect(getByTestId('collaborations-title')).toBeInTheDocument()
  })

  it('shows dropdown when create permission is true and collaborators exist', () => {
    fakeENV.setup({
      context_asset_string: 'courses_1',
      CREATE_PERMISSION: true,
    })
    const {container} = render(<CollaborationsNavigation {...defaultProps} />)
    expect(container.querySelector('.create-collaborations-dropdown')).toBeInTheDocument()
  })

  it('hides dropdown when create permission is false', () => {
    fakeENV.setup({
      context_asset_string: 'courses_1',
      CREATE_PERMISSION: false,
    })
    const {container} = render(<CollaborationsNavigation {...defaultProps} />)
    expect(container.querySelector('.create-collaborations-dropdown')).not.toBeInTheDocument()
  })

  it('hides dropdown when no collaborators exist', () => {
    fakeENV.setup({
      context_asset_string: 'courses_1',
      CREATE_PERMISSION: true,
    })
    const props = {
      ltiCollaborators: {
        ltiCollaboratorsData: [],
      },
    }
    const {container} = render(<CollaborationsNavigation {...props} />)
    expect(container.querySelector('.create-collaborations-dropdown')).not.toBeInTheDocument()
  })
})
