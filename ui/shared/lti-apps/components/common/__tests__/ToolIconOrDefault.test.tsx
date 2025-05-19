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

import {render} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import {ToolIconOrDefault} from '../ToolIconOrDefault'

describe('ToolIConOrDefault', () => {
  const toolName = 'tool&Name'
  const toolId = 1
  const defaultIconUrlRegex = /\/lti\/tool_default_icon\?id=1&name=tool%26Name$/
  const baseProps = {toolName, toolId, size: 32, margin: 1, marginRight: 2}

  function renderGetImg(el: React.ReactElement) {
    const {getByAltText} = render(el)
    return getByAltText(toolName) as HTMLImageElement
  }

  it('renders the icon url with the given size, margin, and marginRight', () => {
    const img = renderGetImg(
      <ToolIconOrDefault iconUrl={'http://instructure.com/iconurl'} {...baseProps} />,
    )
    expect(img.src).toBe('http://instructure.com/iconurl')
    expect(img.style.width).toBe('32px')
    expect(img.style.height).toBe('32px')
    expect(img.style.margin).toBe('1px 2px 1px 1px')
  })

  it('renders the default icon when iconUrl is null', () => {
    const img = renderGetImg(<ToolIconOrDefault iconUrl={null} {...baseProps} />)
    expect(img.src).toMatch(defaultIconUrlRegex)
  })

  it('renders the default icon when iconUrl is undefined', () => {
    const img = renderGetImg(<ToolIconOrDefault iconUrl={undefined} {...baseProps} />)
    expect(img.src).toMatch(defaultIconUrlRegex)
  })

  it('renders the default icon when iconUrl is empty string', () => {
    const img = renderGetImg(<ToolIconOrDefault iconUrl={''} {...baseProps} />)
    expect(img.src).toMatch(defaultIconUrlRegex)
  })
})
