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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Modal from '@canvas/react-modal'
import AddApp from '../AddApp'

describe('ExternalApps.AddApp', () => {
  let container
  let app
  const handleToolInstalled = jest.fn()

  beforeEach(() => {
    container = document.createElement('div')
    container.setAttribute('id', 'fixtures')
    document.body.appendChild(container)
    Modal.setAppElement(container)

    app = {
      config_options: [],
      config_xml_url: 'https://www.eduappcenter.com/configurations/g7lthtepu68qhchz.xml',
      description: 'Acclaim is the easiest way to organize and annotate videos for class.',
      id: 289,
      is_installed: false,
      name: 'Acclaim',
      requires_secret: true,
      short_name: 'acclaim_app',
      status: 'active',
    }
  })

  afterEach(() => {
    container.remove()
    handleToolInstalled.mockReset()
  })

  it('renders the add app component', () => {
    render(<AddApp handleToolInstalled={handleToolInstalled} app={app} />, {container})
    expect(screen.getByRole('link', {name: /add app/i})).toBeInTheDocument()
  })

  it('renders config options with correct field names', async () => {
    const {container: componentContainer} = render(
      <AddApp handleToolInstalled={handleToolInstalled} app={app} />,
      {container},
    )
    const addLink = screen.getByRole('link', {name: /add app/i})
    await userEvent.click(addLink)

    expect(screen.getByLabelText(/name/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/consumer key/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/shared secret/i)).toBeInTheDocument()
  })

  it('initializes with correct config settings', async () => {
    app.config_options = [{name: 'param1', param_type: 'text', default_value: 'val1'}]
    const {container: componentContainer} = render(
      <AddApp handleToolInstalled={handleToolInstalled} app={app} />,
      {container},
    )
    const addLink = screen.getByRole('link', {name: /add app/i})
    await userEvent.click(addLink)

    const param1Input = screen.getByRole('textbox', {name: ''})
    expect(param1Input).toHaveValue('val1')
    expect(screen.getByLabelText(/name/i)).toHaveValue('Acclaim')
  })

  it('initializes with correct field state', async () => {
    const {container: componentContainer} = render(
      <AddApp handleToolInstalled={handleToolInstalled} app={app} />,
      {container},
    )
    const addLink = screen.getByRole('link', {name: /add app/i})
    await userEvent.click(addLink)

    // Check required fields are empty initially
    expect(screen.getByLabelText(/consumer key/i)).toHaveValue('')
    expect(screen.getByLabelText(/shared secret/i)).toHaveValue('')
    // Name should be pre-filled
    expect(screen.getByLabelText(/name/i)).toHaveValue('Acclaim')
  })
})
