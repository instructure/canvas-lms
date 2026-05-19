/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import ConditionalReleaseTabs from '../ConditionalReleaseTabs'
import type {ConditionalReleaseTabsHandle} from '../ConditionalReleaseTabs'

function setupPanels() {
  const panel1 = document.createElement('div')
  panel1.id = 'edit_assignment_wrapper'
  panel1.textContent = 'Details content'
  document.body.appendChild(panel1)

  const panel2 = document.createElement('div')
  panel2.id = 'mastery-paths-editor'
  panel2.style.display = 'none'
  panel2.textContent = 'Mastery Paths content'
  document.body.appendChild(panel2)

  return {panel1, panel2}
}

function getDetailsTab() {
  return screen.getByText('Details').closest('[role="tab"]') as HTMLElement
}

function getMasteryPathsTab() {
  return screen.getByText('Mastery Paths').closest('[role="tab"]') as HTMLElement
}

describe('ConditionalReleaseTabs', () => {
  let panels: ReturnType<typeof setupPanels>

  beforeEach(() => {
    panels = setupPanels()
  })

  afterEach(() => {
    panels.panel1.remove()
    panels.panel2.remove()
  })

  it('renders Details and Mastery Paths tabs', () => {
    render(<ConditionalReleaseTabs onTabChange={vi.fn()} />)
    expect(screen.getByText('Details')).toBeInTheDocument()
    expect(screen.getByText('Mastery Paths')).toBeInTheDocument()
  })

  it('initializes with Details tab selected', () => {
    render(<ConditionalReleaseTabs onTabChange={vi.fn()} />)
    expect(getDetailsTab()).toHaveAttribute('aria-selected', 'true')
  })

  it('shows the details panel and hides mastery paths on initial render', () => {
    render(<ConditionalReleaseTabs onTabChange={vi.fn()} />)
    expect(panels.panel1.style.display).not.toBe('none')
    expect(panels.panel2.style.display).toBe('none')
  })

  it('switches panels when Mastery Paths tab is clicked', async () => {
    const user = userEvent.setup()
    const onTabChange = vi.fn()
    render(<ConditionalReleaseTabs onTabChange={onTabChange} />)

    await user.click(screen.getByText('Mastery Paths'))

    expect(panels.panel1.style.display).toBe('none')
    expect(panels.panel2.style.display).toBe('')
    expect(onTabChange).toHaveBeenCalled()
  })

  it('switches back to Details when Details tab is clicked', async () => {
    const user = userEvent.setup()
    render(<ConditionalReleaseTabs onTabChange={vi.fn()} />)

    await user.click(screen.getByText('Mastery Paths'))
    await user.click(screen.getByText('Details'))

    expect(panels.panel1.style.display).toBe('')
    expect(panels.panel2.style.display).toBe('none')
  })

  it('supports programmatic tab switching via ref', () => {
    const ref = React.createRef<ConditionalReleaseTabsHandle>()
    render(<ConditionalReleaseTabs ref={ref} onTabChange={vi.fn()} />)

    ref.current!.setActiveIndex(1)
    expect(panels.panel1.style.display).toBe('none')
    expect(panels.panel2.style.display).toBe('')

    ref.current!.setActiveIndex(0)
    expect(panels.panel1.style.display).toBe('')
    expect(panels.panel2.style.display).toBe('none')
  })

  it('disables the Mastery Paths tab', () => {
    const ref = React.createRef<ConditionalReleaseTabsHandle>()
    render(<ConditionalReleaseTabs ref={ref} onTabChange={vi.fn()} />)

    ref.current!.setDisabledIndices([1])
    expect(getMasteryPathsTab()).toHaveAttribute('aria-disabled', 'true')
  })

  it('does not switch to a disabled tab on click', async () => {
    const user = userEvent.setup()
    const ref = React.createRef<ConditionalReleaseTabsHandle>()
    render(<ConditionalReleaseTabs ref={ref} onTabChange={vi.fn()} />)

    ref.current!.setDisabledIndices([1])
    await user.click(screen.getByText('Mastery Paths'))

    // Still on Details tab
    expect(getDetailsTab()).toHaveAttribute('aria-selected', 'true')
    expect(panels.panel1.style.display).not.toBe('none')
    expect(panels.panel2.style.display).toBe('none')
  })

  it('re-enables tabs when setDisabledIndices is called with empty array', () => {
    const ref = React.createRef<ConditionalReleaseTabsHandle>()
    render(<ConditionalReleaseTabs ref={ref} onTabChange={vi.fn()} />)

    ref.current!.setDisabledIndices([1])
    expect(getMasteryPathsTab()).toHaveAttribute('aria-disabled', 'true')

    ref.current!.setDisabledIndices([])
    expect(getMasteryPathsTab()).not.toHaveAttribute('aria-disabled', 'true')
  })
})
