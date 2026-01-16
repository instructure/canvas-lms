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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CreateFromTemplate from '../CreateFromTemplate'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import fakeEnv from '@canvas/test-utils/fakeENV'

type EnvWithWikiPage = GlobalEnv & {
  WIKI_PAGE: any
}
declare const window: Window & {ENV: EnvWithWikiPage}

const user = userEvent.setup()

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

describe('CreateFromTemplate', () => {
  beforeAll(() => {
    fakeEnv.setup({WIKI_PAGE: undefined})
  })

  afterAll(() => {
    fakeEnv.teardown()
  })

  it('filters on the menu of tags', async () => {
    await renderComponent()

    expect(
      document.querySelectorAll('[role="menuitemcheckbox"][aria-checked="true"]'),
    ).toHaveLength(0)

    await user.click(screen.getByText('Apply Filters').closest('button') as HTMLButtonElement)

    await waitFor(() => {
      expect(
        document.querySelectorAll('[role="menuitemcheckbox"][aria-checked="true"]'),
      ).toHaveLength(5)
    })

    // Deselect one tag from the menu
    await user.click(document.querySelectorAll('[role="menuitemcheckbox"]')[1])

    await waitFor(() => {
      // Should show fewer templates after deselecting one tag
      const cards = document.querySelectorAll('.block-template-preview-card')
      expect(cards.length).toBeLessThan(totalCards)
    })
  })
})
