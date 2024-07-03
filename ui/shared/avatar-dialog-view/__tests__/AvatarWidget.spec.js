/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import 'jquery-migrate'
import '@testing-library/jest-dom'
import {fireEvent} from '@testing-library/dom'
import AvatarWidget from '../AvatarWidget'

describe('AvatarWidget', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.setAttribute('id', 'fixtures')
    document.body.appendChild(container)
  })

  afterEach(() => {
    document.body.removeChild(container)
  })

  test('opens dialog on element click', () => {
    const targetElement = document.createElement('a')
    targetElement.setAttribute('href', '#')
    targetElement.setAttribute('id', 'avatar-opener')
    targetElement.textContent = 'Click'
    container.appendChild(targetElement)

    // Initialize the AvatarWidget on the target element
    new AvatarWidget(targetElement) // Assuming AvatarWidget binds click event handlers

    fireEvent.click(targetElement)

    // Check if the dialog is opened by searching for .avatar-nav in the document
    expect(document.querySelector('.avatar-nav')).toBeInTheDocument()
  })
})
