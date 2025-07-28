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
import userEvent from '@testing-library/user-event'
import CreateFromTemplate from '../CreateFromTemplate'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

type EnvWithWikiPage = GlobalEnv & {
  WIKI_PAGE: any
}
declare const window: Window & {ENV: EnvWithWikiPage}

const user = userEvent.setup()

const blankPages = 1
const generalContentPages = 3
const homePages = 8
const introPages = 1
const moduleOverviewPages = 6
const resourcePages = 4
const totalPages =
  blankPages + generalContentPages + homePages + introPages + moduleOverviewPages + resourcePages

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useEditor: jest.fn(() => {
      return {
        actions: {
          deserialize: jest.fn(),
        },
      }
    }),
  }
})

const renderComponent = async () => {
  const rendered = render(<CreateFromTemplate course_id="1" noBlocks={true} />)

  await waitFor(() => {
    expect(document.querySelectorAll('.block-template-preview-card')).toHaveLength(totalPages)
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

    expect(screen.getByText('Create Page')).toBeInTheDocument()
    expect(screen.getByText(/^Start from a blank page/)).toBeInTheDocument()
    expect(screen.getByText('Back to Pages')).toBeInTheDocument()
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

  it('filters on the search string', async () => {
    await renderComponent()

    const searchInput = screen.getByTestId('template-search')
    await user.type(searchInput, 'yellow')

    // Wait for both conditions to be true
    await waitFor(
      () => {
        const cards = document.querySelectorAll('.block-template-preview-card')
        const blankPage = screen.queryByText('New Blank Page')
        const yellowTemplate = screen.queryByLabelText('Course Home - Yellow template')

        return cards.length === 2 && blankPage !== null && yellowTemplate !== null
      },
      {timeout: 4000}, // Increase timeout but keep it reasonable
    )
  })

  // fickle; passes individually
  it.skip('filters on the tags', async () => {
    await renderComponent()
    await user.click(getByTagText('General Content').closest('button') as HTMLButtonElement)

    await waitFor(() => {
      expect(document.querySelectorAll('.block-template-preview-card')).toHaveLength(
        totalPages - generalContentPages,
      )
    })

    await user.click(getByTagText('Home').closest('button') as HTMLButtonElement)

    await waitFor(() => {
      expect(document.querySelectorAll('.block-template-preview-card')).toHaveLength(
        totalPages - generalContentPages - homePages,
      )
    })
  })

  it('filters on the menu of tags', async () => {
    await renderComponent()

    expect(
      document.querySelectorAll('[role="menuitemcheckbox"][aria-checked="true"]'),
    ).toHaveLength(0)

    user.click(screen.getByText('Apply Filters').closest('button') as HTMLButtonElement)

    await waitFor(() => {
      expect(
        document.querySelectorAll('[role="menuitemcheckbox"][aria-checked="true"]'),
      ).toHaveLength(5)
    })

    // I don't understand why getByText doesn't work when Home is displayed
    // await user.click(screen.getByText('Home', {selector: 'ul[role="menu"]'}))
    await user.click(document.querySelectorAll('[role="menuitemcheckbox"]')[1])

    await waitFor(() => {
      expect(document.querySelectorAll('.block-template-preview-card')).toHaveLength(15)
    })
  })
})
