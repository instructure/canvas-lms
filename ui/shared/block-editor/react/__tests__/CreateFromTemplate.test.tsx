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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useEditor} from '@craftjs/core'
import {render, screen, waitFor, getByText} from '@testing-library/react'
import CreateFromTemplate from '../CreateFromTemplate'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

type EnvWithWikiPage = GlobalEnv & {
  WIKI_PAGE: any
}
declare const window: Window & {ENV: EnvWithWikiPage}

const mockNodeTree = {
  rootNodeId: 'ROOT',
  nodes: {
    ROOT: {
      type: {resolvedName: 'PageBlock'},
      isCanvas: true,
      props: {},
      displayName: 'Page',
      custom: {},
      hidden: false,
      nodes: [],
      linkedNodes: {},
    },
  },
}

const mockTemplates = [
  {
    id: 'blank_page',
    name: 'Blank Page',
    description: '',
    tags: [],
    editor_version: '0.3',
    node_tree: mockNodeTree,
  },
  {
    id: 'home_yellow',
    name: 'Course Home - Yellow',
    description: 'Home page with yellow theme',
    tags: ['home'],
    editor_version: '0.3',
    node_tree: mockNodeTree,
  },
  {
    id: 'home_blue',
    name: 'Course Home - Blue',
    description: 'Home page with blue theme',
    tags: ['home'],
    editor_version: '0.3',
    node_tree: mockNodeTree,
  },
  {
    id: 'content_1',
    name: 'Content Page 1',
    description: 'General content',
    tags: ['generalcontent'],
    editor_version: '0.3',
    node_tree: mockNodeTree,
  },
  {
    id: 'intro_1',
    name: 'Introduction Page',
    description: 'Introduction',
    tags: ['intro'],
    editor_version: '0.3',
    node_tree: mockNodeTree,
  },
  {
    id: 'module_1',
    name: 'Module Overview',
    description: 'Module overview',
    tags: ['moduleoverview'],
    editor_version: '0.3',
    node_tree: mockNodeTree,
  },
  {
    id: 'resource_1',
    name: 'Resource Page',
    description: 'Resource',
    tags: ['resource'],
    editor_version: '0.3',
    node_tree: mockNodeTree,
  },
]

const totalCards = mockTemplates.length

vi.mock('@craftjs/core', async () => {
  const actual = await vi.importActual('@craftjs/core')
  return {
    ...actual,
    useEditor: vi.fn(() => {
      return {
        actions: {
          deserialize: vi.fn(),
        },
      }
    }),
  }
})

vi.mock('@canvas/block-editor/react/assets/globalTemplates', () => ({
  getGlobalPageTemplates: vi.fn(() => Promise.resolve([...mockTemplates])),
}))

const renderComponent = async () => {
  const rendered = render(<CreateFromTemplate course_id="1" noBlocks={true} />)

  await waitFor(() => {
    expect(document.querySelectorAll('.block-template-preview-card')).toHaveLength(totalCards)
  })
  return rendered
}

const getByTagText = (tag: string) => {
  return getByText(screen.getByTestId('active-tags'), tag)
}

describe('CreateFromTemplate', () => {
  beforeAll(() => {
    // @ts-expect-error
    window.ENV ||= {}
    window.ENV.WIKI_PAGE = undefined
  })

  it('renders', async () => {
    await renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Create Page')).toBeInTheDocument()
      expect(screen.getByText(/^Start from a blank page/)).toBeInTheDocument()
      expect(screen.getByText('Back to Pages')).toBeInTheDocument()
    })

    expect(screen.getByText('Clear All Filters')).toBeInTheDocument()
    expect(getByTagText('General Content')).toBeInTheDocument()
    expect(getByTagText('Home')).toBeInTheDocument()
    expect(getByTagText('Introduction')).toBeInTheDocument()
    expect(getByTagText('Module Overview')).toBeInTheDocument()
    expect(getByTagText('Resource')).toBeInTheDocument()
    expect(screen.getByText('Apply Filters')).toBeInTheDocument()
    expect(screen.getByTestId('template-search')).toBeInTheDocument()
    expect(screen.getByText('New Blank Page')).toBeInTheDocument()
    expect(screen.getByLabelText('Course Home - Yellow template')).toBeInTheDocument()
  })
})
