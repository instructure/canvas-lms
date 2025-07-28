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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Modal from '@canvas/react-modal'
import ReregisterExternalToolButton from '../ReregisterExternalToolButton'
import store from '../../lib/ExternalAppsStore'

const tools = [
  {
    app_id: 2,
    app_type: 'Lti::ToolProxy',
    description: null,
    enabled: true,
    installed_locally: true,
    name: 'SomeTool',
    reregistration_url: 'http://some.lti/reregister',
  },
]

describe('ExternalApps.ReregisterExternalToolButton', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.setAttribute('id', 'fixtures')
    document.body.appendChild(container)
    Modal.setAppElement(container)
    store.reset()
    store.setState({externalTools: tools})
  })

  afterEach(() => {
    store.reset()
    container.remove()
  })

  it('opens and closes modal', async () => {
    render(<ReregisterExternalToolButton tool={tools[0]} canAdd={true} returnFocus={() => {}} />, {
      container,
    })

    const reregisterLink = screen.getByRole('menuitem', {name: /reregister sometool/i})
    userEvent.click(reregisterLink)

    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument()
    })

    const closeButton = screen.getByRole('button', {name: /close/i})
    userEvent.click(closeButton)

    await waitFor(() => {
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
    })
  })
})
