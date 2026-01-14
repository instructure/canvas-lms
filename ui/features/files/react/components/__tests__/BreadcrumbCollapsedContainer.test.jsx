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

import React from 'react'
import {render, cleanup, fireEvent} from '@testing-library/react'
import BreadcrumbCollapsedContainer from '../BreadcrumbCollapsedContainer'
import stubRouterContext from '../../../../../shared/test-utils/stubRouterContext'

// Mock filesEnv to avoid Backbone model loading issues in Vitest
vi.mock('@canvas/files/react/modules/filesEnv', () => ({
  default: {
    contexts: [],
    userFileAccessRestricted: false,
    contextsDictionary: {},
    showingAllContexts: false,
    contextType: undefined,
    contextId: undefined,
    rootFolders: [],
    enableVisibility: false,
    contextFor: vi.fn(),
    userHasPermission: vi.fn(() => false),
    baseUrl: '/files',
  },
}))

// Mock Folder class
class MockFolder {
  constructor(attrs) {
    this.attrs = attrs
  }
  get(key) {
    return this.attrs[key]
  }
  url() {
    return this.attrs.url || 'stupid'
  }
  urlPath() {
    return this.attrs.urlPath || this.attrs.url || 'test_url'
  }
}

const Folder = MockFolder

describe('BreadcrumbsCollapsedContainer', () => {
  let Component

  beforeEach(() => {
    const folder = new Folder({name: 'Test Folder', urlPath: 'test_url', url: 'stupid'})
    folder.url = () => 'stupid'

    const props = {foldersToContain: [folder]}
    Component = stubRouterContext(BreadcrumbCollapsedContainer, props)
  })

  afterEach(cleanup)

  it('opens breadcrumbs on mouse enter', () => {
    const {getByText} = render(<Component />)
    const ellipsis = getByText('…').closest('li')
    fireEvent.mouseEnter(ellipsis)
    expect(ellipsis.querySelector('.open')).toBeTruthy()
  })

  it('opens breadcrumbs on focus', () => {
    const {getByText} = render(<Component />)
    const ellipsis = getByText('…').closest('li')
    fireEvent.focus(ellipsis)
    expect(ellipsis.querySelector('.open')).toBeTruthy()
  })

  it('closes breadcrumbs on mouse leave', () => {
    vi.useFakeTimers()
    const {getByText} = render(<Component />)
    const ellipsis = getByText('…').closest('li')
    fireEvent.mouseLeave(ellipsis)
    vi.advanceTimersByTime(200)
    expect(ellipsis.querySelector('.closed')).toBeTruthy()
    vi.useRealTimers()
  })

  it('closes breadcrumbs on blur', () => {
    vi.useFakeTimers()
    const {getByText} = render(<Component />)
    const ellipsis = getByText('…').closest('li')
    fireEvent.blur(ellipsis)
    vi.advanceTimersByTime(200)
    expect(ellipsis.querySelector('.closed')).toBeTruthy()
    vi.useRealTimers()
  })
})
