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
    // @ts-expect-error
    window.ENV ||= {}
    window.ENV.WIKI_PAGE = undefined
  })

  it('filters on the search string', async () => {
    const user = userEvent.setup()
    await renderComponent()

    const searchInput = screen.getByPlaceholderText('Search')

    // Wait for the input to become enabled before interacting
    await waitFor(() => {
      expect(searchInput).not.toHaveAttribute('disabled')
    })

    // Use paste for faster input in CI
    await user.click(searchInput)
    await user.paste('yellow')

    await waitFor(() => {
      expect(screen.queryByLabelText('Course Home - Blue template')).not.toBeInTheDocument()
    })

    expect(screen.queryByLabelText('Course Home - Yellow template')).toBeInTheDocument()
    const cards = document.querySelectorAll('.block-template-preview-card')
    expect(cards.length).toBeLessThanOrEqual(2)
  })
})
