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
import {render} from '@testing-library/react'

import LtiTool from '../LtiTool'

describe('RCE Plugins > LtiTool', () => {

  function getProps(override={}) {
    const props = {
      title: "Tool 1",
      id: 1,
      description: "This is tool 1.",
      image: "tool1/icon.png",
      onAction: () => {},
      ...override
    }
    return props
  }

  function renderComponent(toolprops) {
    return render(<LtiTool {...getProps(toolprops)} />)
  }

  it('renters the tool title', () => {
    const {getByText} = renderComponent()
    expect(getByText("Tool 1")).toBeInTheDocument()
  })

  it('renters the tool image', () => {
    const {container} = renderComponent()
    expect(container.querySelector('img[src="tool1/icon.png"]')).toBeInTheDocument()
  })

  it('renders the tool description', () => {
    const {getByText} = renderComponent()
    expect(getByText("This is tool 1.")).toBeInTheDocument()
  })
})
