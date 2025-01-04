/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import NewCollaborationsDropDown from '../NewCollaborationsDropDown'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('NewCollaborationsDropDown', () => {
  const defaultProps = {
    ltiCollaborators: [{name: 'A name', id: '1'}],
  }

  beforeEach(() => {
    fakeENV.setup({
      context_asset_string: 'courses_1',
      CREATE_PERMISSION: true,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders the create-collaborations-dropdown div', () => {
    const {getByTestId} = render(<NewCollaborationsDropDown {...defaultProps} />)
    expect(getByTestId('new-collaborations-dropdown')).toBeInTheDocument()
  })

  it('has a link to open the lti tool to create a collaboration', () => {
    const {getByRole} = render(<NewCollaborationsDropDown {...defaultProps} />)
    const button = getByRole('link')
    expect(button).toHaveAttribute(
      'href',
      '/courses/1/lti_collaborations/external_tools/1?launch_type=collaboration&display=borderless',
    )
  })

  it('has a dropdown if there is more than one tool', async () => {
    const props = {
      ltiCollaborators: [
        {
          name: 'A name',
          id: '1',
          collaboration: {text: 'Tool 1'},
        },
        {
          name: 'Another name',
          id: '2',
          collaboration: {text: 'Tool 2'},
        },
      ],
    }

    const {getByRole, getByText} = render(<NewCollaborationsDropDown {...props} />)
    const dropdownButton = getByRole('button')
    await userEvent.click(dropdownButton)

    expect(getByText('Tool 1')).toBeInTheDocument()
    expect(getByText('Tool 2')).toBeInTheDocument()
  })
})
