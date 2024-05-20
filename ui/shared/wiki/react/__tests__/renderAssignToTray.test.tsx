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

import {render, waitFor} from '@testing-library/react'
import {renderAssignToTray} from '../renderAssignToTray'

const props = {pageId: '1', onSync: () => {}, pageName: 'Test page'}

describe('renderAssignToTray', () => {
  const container = document.createElement('div')
  container.id = 'assign-to-mount-point'

  it('renders the Assign To option', () => {
    const assignToOption = renderAssignToTray(container, props)

    const {getByTestId} = render(assignToOption)
    const assignToButton = getByTestId('manage-assign-to')
    expect(assignToButton).toBeInTheDocument()
  })

  it('opens the AssignToTray on click', async () => {
    const assignToOption = renderAssignToTray(container, props)

    const {findByText, getByTestId} = render(assignToOption)
    getByTestId('manage-assign-to').click()
    const trayTitle = await findByText(props.pageName)
    expect(trayTitle).toBeInTheDocument()
  })

  it('sets default state for new pages', async () => {
    const assignToOption = renderAssignToTray(container, {...props, pageId: undefined})

    const {findAllByTestId, getByTestId} = render(assignToOption)
    getByTestId('manage-assign-to').click()
    const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
    expect(selectedOptions).toHaveLength(1)
    waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Everyone'))
  })
})
