/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import DeleteExternalToolButton from '../DeleteExternalToolButton'
import {render, screen, waitFor, waitForElementToBeRemoved} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import store from '../../lib/ExternalAppsStore'

const renderComponent = data => render(<DeleteExternalToolButton {...data} />)
const getDOMNodes = function (data) {
  const component = renderComponent(data)
  const btnTriggerDelete = component.refs.btnTriggerDelete
  return [component, btnTriggerDelete]
}

jest.mock('../../lib/ExternalAppsStore')

describe('ExternalApps.DeleteExternalToolButton', () => {
  let tools
  beforeAll(() => {
    userEvent.setup()
  })
  beforeEach(() => {
    tools = [
      {
        app_id: 1,
        app_type: 'ContextExternalTool',
        description:
          'Talent provides an online, interactive video platform for professional development',
        enabled: true,
        installed_locally: true,
        name: 'Talent',
      },
      {
        app_id: 2,
        app_type: 'Lti::ToolProxy',
        description: null,
        enabled: true,
        installed_locally: true,
        name: 'Twitter',
      },
    ]
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  test('does not render when the canAddEdit permission is false', () => {
    const tool = {name: 'test tool'}
    renderComponent({tool, canAddEdit: false, canDelete: false, returnFocus: () => {}})
    expect(screen.queryByText('Delete')).not.toBeInTheDocument()
  })

  test('open and close modal', async () => {
    const ref = React.createRef()
    const data = {tool: tools[1], canAddEdit: true, canDelete: false, returnFocus: jest.fn(), ref}
    renderComponent(data)

    await userEvent.click(screen.getByText(/delete/i))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    await userEvent.click(screen.getAllByRole('button', {name: /close/i})[0])
    expect(data.returnFocus).toHaveBeenCalled()
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })

  test('deletes a tool', async () => {
    renderComponent({
      tool: tools[0],
      canAddEdit: true,
      canDelete: true,
      returnFocus: () => {},
    })
    // Open the modal
    await userEvent.click(screen.getByRole('button', {name: /delete/i}))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    // Actually delete the tool
    await userEvent.click(screen.getByTestId('modal-delete-button'))
    expect(store.delete).toHaveBeenCalled()
  })

  test('does not render when the canDelete permission is false (granular)', () => {
    renderComponent({
      tool: tools[0],
      canDelete: false,
      canAddEdit: false,
      returnFocus: () => {},
    })

    expect(screen.queryByText('Delete')).not.toBeInTheDocument()
  })

  test('open and close modal (granular)', async () => {
    const ref = React.createRef()
    const data = {tool: tools[1], canAddEdit: false, canDelete: true, returnFocus: jest.fn(), ref}
    renderComponent(data)

    await userEvent.click(screen.getByText(/delete/i))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    await userEvent.click(screen.getAllByRole('button', {name: /close/i})[0])
    expect(data.returnFocus).toHaveBeenCalled()
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })

  test('deletes a tool (granular)', async () => {
    renderComponent({
      tool: tools[0],
      canAddEdit: false,
      canDelete: true,
      returnFocus: () => {},
    })
    // Open the modal
    await userEvent.click(screen.getByRole('button', {name: /delete/i}))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    // Actually delete the tool
    await userEvent.click(screen.getByTestId('modal-delete-button'))
    expect(store.delete).toHaveBeenCalled()
  })
})
