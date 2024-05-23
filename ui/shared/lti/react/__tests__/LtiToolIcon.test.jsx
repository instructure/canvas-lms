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
import {LtiToolIcon} from '../LtiToolIcon'

const tool = {
  id: '1',
  title: 'Tool Title',
  description: 'The tool description.',
  icon_url: 'https://www.example.com/icon.png',
}

describe('LtiToolIcon', () => {
  it('renders an icon as given', () => {
    render(<LtiToolIcon tool={tool} />)
    const img = document.querySelector('img')
    expect(img.src).toBe(tool.icon_url)
  })

  it('renders a default tool icon when no icon_url is supplied', () => {
    const _tool = {...tool}
    delete _tool.icon_url
    render(<LtiToolIcon tool={_tool} />)
    const img = document.querySelector('img')
    expect(img.src).toContain('/lti/tool_default_icon?id=1&name=%22Tool%20Title%22')
  })
})
