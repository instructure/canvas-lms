/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

/**
 * @vi-environment jsdom
 */

// Mock the ready function to immediately execute the callback
vi.mock('@instructure/ready', () => (callback: () => void) => callback())

// Mock the React components to avoid actual rendering
vi.mock('@canvas/trays/react/ContentTypeExternalToolDrawer', () => () => null)
vi.mock('../react/TopNavigationTools', () => ({
  TopNavigationTools: () => null,
  MobileTopNavigationTools: () => null,
}))

// Mock ENV
;(global as any).ENV = {
  top_navigation_tools: [],
}

describe('href="#" scrollTop fix', () => {
  let mockDrawerContent: HTMLElement
  let scrollToSpy: any

  beforeEach(() => {
    // Reset DOM
    document.body.innerHTML = ''

    // Create required mount points to satisfy the module's checks
    const drawerLayoutMountPoint = document.createElement('div')
    drawerLayoutMountPoint.id = 'drawer-layout-mount-point'
    document.body.appendChild(drawerLayoutMountPoint)

    const topNavToolsMountPoint = document.createElement('div')
    topNavToolsMountPoint.id = 'top-nav-tools-mount-point'
    document.body.appendChild(topNavToolsMountPoint)

    const canvasApplicationBody = document.createElement('div')
    canvasApplicationBody.id = 'application'
    document.body.appendChild(canvasApplicationBody)

    // Create mock drawer content element
    mockDrawerContent = document.createElement('div')
    mockDrawerContent.id = 'drawer-layout-content'
    mockDrawerContent.scrollTop = 100 // Simulate scrolled state
    document.body.appendChild(mockDrawerContent)

    // Mock scrollTo method
    scrollToSpy = vi.fn()
    Object.defineProperty(mockDrawerContent, 'scrollTo', {
      value: scrollToSpy,
      writable: true,
    })

    // Mock document properties for non-scrollable HTML
    Object.defineProperty(document.documentElement, 'scrollHeight', {
      configurable: true,
      get: () => 800,
    })
    Object.defineProperty(document.documentElement, 'clientHeight', {
      configurable: true,
      get: () => 800, // Equal heights = can't scroll
    })

    // Load the module to register the event listener
    vi.resetModules()
     
    require('../index.tsx')
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it.skip('scrolls drawer content to top when href="#" is clicked and HTML cannot scroll', () => {
    // Create a link with href="#"
    const link = document.createElement('a')
    link.href = '#'
    link.textContent = 'Scroll to top'
    document.body.appendChild(link)

    // Simulate click event
    link.click()

    // Should have called scrollTo on drawer content
    expect(scrollToSpy).toHaveBeenCalledWith({top: 0})
  })

  it.skip('does not interfere when HTML element can scroll normally', () => {
    // Make HTML scrollable
    Object.defineProperty(document.documentElement, 'scrollHeight', {
      configurable: true,
      get: () => 1000, // Greater than clientHeight = can scroll
    })

    const link = document.createElement('a')
    link.href = '#'
    document.body.appendChild(link)

    link.click()

    // Should not interfere with default behavior
    expect(scrollToSpy).not.toHaveBeenCalled()
  })

  it.skip('does not trigger when drawer content is already at top', () => {
    // Set drawer content to already be at top
    mockDrawerContent.scrollTop = 0

    const link = document.createElement('a')
    link.href = '#'
    document.body.appendChild(link)

    link.click()

    // Should not call scrollTo when already at top
    expect(scrollToSpy).not.toHaveBeenCalled()
  })

  it.skip('ignores clicks on non-anchor elements', () => {
    const button = document.createElement('button')
    button.textContent = 'Not a link'
    document.body.appendChild(button)

    button.click()

    expect(scrollToSpy).not.toHaveBeenCalled()
  })

  it.skip('ignores anchors with different href values', () => {
    const link = document.createElement('a')
    link.href = '#section1'
    document.body.appendChild(link)

    link.click()

    expect(scrollToSpy).not.toHaveBeenCalled()
  })
})
