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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Collaboration from '../Collaboration'
import fakeENV from '@canvas/test-utils/fakeENV'

const props = {
  collaboration: {
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: new Date(0).toString(),
    update_url: 'http://google.com',
    id: 1,
    permissions: {
      update: true,
      delete: true,
    },
  },
}

describe('Collaboration', () => {
  beforeEach(() => {
    fakeENV.setup({context_asset_string: 'courses_1'})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders a link to the user who created the collaboration', () => {
    render(<Collaboration {...props} />)
    const authorLink = screen.getByTestId('collaboration-author')
    expect(authorLink).toBeInTheDocument()
    expect(authorLink.href).toContain('/users/1')
  })

  it('when the user clicks the trash button it opens the delete confirmation', async () => {
    render(<Collaboration {...props} />)
    await userEvent.click(screen.getByTestId('delete-collaboration'))
    expect(screen.getByTestId('delete-confirmation')).toBeInTheDocument()
  })

  it('when the user clicks the cancel button on the delete confirmation it removes the delete confirmation', async () => {
    render(<Collaboration {...props} />)
    await userEvent.click(screen.getByTestId('delete-collaboration'))
    await userEvent.click(screen.getByRole('button', {name: /cancel/i}))
    expect(screen.queryByTestId('delete-confirmation')).not.toBeInTheDocument()
  })

  it('has an edit button that links to the proper url', () => {
    render(<Collaboration {...props} />)
    const editLink = screen.getByTestId('edit-collaboration')
    expect(editLink.href).toContain(
      `/courses/1/lti_collaborations/external_tools/retrieve?content_item_id=${props.collaboration.id}&placement=collaboration&url=${props.collaboration.update_url}&display=borderless`,
    )
  })
})
