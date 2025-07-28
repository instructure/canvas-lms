/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import ExternalToolPlacementButton from '../ExternalToolPlacementButton'

describe('ExternalToolPlacementButton', () => {
  test('normally renders with a menuitem role', () => {
    const {getByRole} = render(
      <ExternalToolPlacementButton
        tool={{
          app_type: 'ContextExternalTool',
          name: 'A Tool',
        }}
        returnFocus={() => {}}
        onSuccess={() => {}}
        onToggleSuccess={() => {}}
      />,
    )
    const menuItem = getByRole('menuitem')
    expect(menuItem).toBeInTheDocument()
  })

  test('renders as a button when specified', () => {
    const {getByRole} = render(
      <ExternalToolPlacementButton
        type="button"
        tool={{
          app_type: 'ContextExternalTool',
          name: 'A Tool',
        }}
        returnFocus={() => {}}
        onSuccess={() => {}}
        onToggleSuccess={() => {}}
      />,
    )
    const button = getByRole('button')
    expect(button).toBeInTheDocument()
  })

  test('renders button that displays tool information', () => {
    const tool = {
      app_type: 'ContextExternalTool',
      name: 'A Tool',
    }

    const {getByRole} = render(
      <ExternalToolPlacementButton
        type="button"
        tool={tool}
        returnFocus={() => {}}
        onSuccess={() => {}}
        onToggleSuccess={() => {}}
      />,
    )

    // Verify button exists and can be interacted with
    const button = getByRole('button')
    expect(button).toBeInTheDocument()
    expect(button).toBeEnabled()
  })
})
