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

import React from 'react'
import {render} from '@testing-library/react'
import {ToolbarColor} from '../ToolbarColor'

describe('ToolbarColor', () => {
  it('renders the button', () => {
    const {getByText} = render(<ToolbarColor bgcolor="#fff" fgcolor="#000" onChange={jest.fn()} />)

    const button = getByText('Color').closest('button')

    expect(button).toBeInTheDocument()
  })

  it('renders the popup', () => {
    const {getAllByRole, getByText} = render(
      <ToolbarColor bgcolor="#fff" fgcolor="#000" onChange={jest.fn()} />
    )
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')

    expect(tabs[0]).toHaveTextContent('Color')
    expect(tabs[1]).toHaveTextContent('Background Color')
  })

  it('includes the default foreground color', () => {
    window.getComputedStyle = jest.fn().mockReturnValue({
      getPropertyValue: jest.fn().mockReturnValue('defaultcolor'),
    })
    const {getByText} = render(<ToolbarColor bgcolor="#fff" fgcolor="#000" onChange={jest.fn()} />)

    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const c1 = document.getElementById(
      // @ts-expect-error
      document
        .getElementById('foreground')
        ?.querySelectorAll('button')[0]
        ?.getAttribute('aria-describedby')
    )
    expect(c1).toHaveTextContent('defaultcolor')
  })

  it('switches to the background tab', () => {
    const {getAllByRole, getByText} = render(
      <ToolbarColor bgcolor="#fff" fgcolor="#000" onChange={jest.fn()} />
    )
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')

    tabs[1].click()

    expect(tabs[1]).toHaveAttribute('aria-selected', 'true')
    expect(document.getElementById('background')).toBeInTheDocument()
  })
})
