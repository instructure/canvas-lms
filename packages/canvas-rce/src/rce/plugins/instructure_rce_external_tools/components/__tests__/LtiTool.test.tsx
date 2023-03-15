/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, within} from '@testing-library/react'

import ExternalToolSelectionItem, {
  LtiToolProps,
} from '../ExternalToolSelectionDialog/ExternalToolSelectionItem'

describe('RCE Plugins > ExternalToolSelectionItem', () => {
  function buildProps(overrides: Partial<LtiToolProps> = {}): LtiToolProps {
    return {
      title: 'Tool 1',
      description: 'This is tool 1.',
      image: 'tool1/icon.png',
      onAction: () => null,
      ...overrides,
    }
  }

  function renderComponent(propOverrides: Partial<LtiToolProps> = {}) {
    return render(<ExternalToolSelectionItem {...buildProps(propOverrides)} />)
  }

  it('renters the tool title', () => {
    const {getByText} = renderComponent()
    expect(getByText('Tool 1')).toBeInTheDocument()
  })

  it('renters the tool image', () => {
    const {container} = renderComponent()
    expect(container.querySelector('img[src="tool1/icon.png"]')).toBeInTheDocument()
  })

  it('renders the tool description', () => {
    const {getByText} = renderComponent()
    const tool = getByText('Tool 1')
    const toolRow = within(tool.closest('div')!)
    expect(toolRow.getByText('View description')).toBeInTheDocument()
  })
})
