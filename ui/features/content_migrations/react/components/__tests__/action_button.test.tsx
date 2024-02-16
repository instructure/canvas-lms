/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {ActionButton} from '../action_button'

jest.mock('@canvas/do-fetch-api-effect')

const generateMigrationIssues = (length: number) => {
  const data = []
  for (let i = 1; i <= length; i++) {
    data.push({
      id: i,
      description: `My description ${i}`,
      workflow_state: 'active',
      fix_issue_html_url: 'https://mock.fix.url',
      issue_type: 'error',
      created_at: '1997-04-15T00:00:00Z',
      updated_at: '1997-04-15T00:00:00Z',
      content_migration_url: 'https://mock.migration.url',
      error_message: `My error message${i}`,
    })
  }
  return data
}

const renderComponent = (overrideProps?: any) =>
  render(
    <ActionButton
      migration_type_title="Canvas Cartridge Importer"
      migration_issues_count={1}
      migration_issues_url="https://mock.issues.url"
      {...{...overrideProps}}
    />
  )

describe('ActionButton', () => {
  afterEach(() => jest.clearAllMocks())

  it('renders button when issues count is greater than zero', () => {
    renderComponent()
    expect(screen.getByRole('button', {name: 'View Issues'})).toBeInTheDocument()
  })

  it('does not render button when issues count is zero', () => {
    renderComponent({migration_issues_count: 0})
    expect(screen.queryByRole('button', {name: 'View Issues'})).not.toBeInTheDocument()
  })

  describe('modal', () => {
    beforeEach(() =>
      doFetchApi.mockReturnValue(Promise.resolve({json: generateMigrationIssues(1)}))
    )

    afterEach(() => {
      jest.clearAllMocks()
      jest.resetAllMocks()
    })

    it('opens on click', async () => {
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
      expect(
        screen.getByRole('heading', {name: 'Canvas Cartridge Importer Issues'})
      ).toBeInTheDocument()
    })

    it('fetch issues list', async () => {
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
      expect(doFetchApi).toHaveBeenCalled()
    })

    it('shows issues list', async () => {
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
      const link = await screen.findByRole('link')
      expect(link).toHaveAttribute('href', 'https://mock.fix.url')
      expect(link).toHaveTextContent('My description 1')
    })

    describe('has more issues', () => {
      beforeEach(() => {
        const issues = generateMigrationIssues(15)
        const page1 = issues.slice(0, 10)
        const page2 = issues.slice(10, 15)
        doFetchApi
          .mockReturnValueOnce(Promise.resolve({json: page1}))
          .mockReturnValueOnce(Promise.resolve({json: page2}))
      })

      it('shows "Show More" button', async () => {
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        expect(await screen.findByRole('button', {name: 'Show More'})).toBeInTheDocument()
      })

      it('"Show More" button calls fetch', async () => {
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        await userEvent.click(await screen.findByRole('button', {name: 'Show More'}))

        expect(doFetchApi).toHaveBeenCalledWith({
          path: 'https://mock.issues.url/?page=2&per_page=10',
          method: 'GET',
        })
      })

      it('"Show More" updates issues list', async () => {
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        await userEvent.click(await screen.findByRole('button', {name: 'Show More'}))

        expect(await screen.findByRole('link', {name: 'My description 1'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 2'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 3'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 4'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 5'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 6'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 7'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 8'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 9'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 10'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 11'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 12'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 13'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 14'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 15'})).toBeInTheDocument()
      })

      it('shows alert if fetch fails', async () => {
        doFetchApi.mockReset()
        doFetchApi
          .mockReturnValueOnce(Promise.resolve({json: generateMigrationIssues(10)}))
          .mockImplementationOnce(() => Promise.reject())
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        await userEvent.click(await screen.findByRole('button', {name: 'Show More'}))

        expect(
          await screen.findByText('Failed to fetch migration issues data.')
        ).toBeInTheDocument()
      })

      it.skip('shows spinner when loading more issues', async () => {
        doFetchApi
          .mockReturnValueOnce(Promise.resolve({json: generateMigrationIssues(10)}))
          .mockReturnValueOnce(new Promise(resolve => setTimeout(resolve, 5000)))
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        await userEvent.click(await screen.findByRole('button', {name: 'Show More'}))
        expect(screen.getByText('Loading more issues')).toBeInTheDocument()
      })
    })

    it('shows alert if fetch fails', async () => {
      doFetchApi.mockImplementation(() => Promise.reject())
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))

      expect(await screen.findByText('Failed to fetch migration issues data.')).toBeInTheDocument()
    })

    it('shows spinner when loading', async () => {
      doFetchApi.mockReturnValue(new Promise(resolve => setTimeout(resolve, 5000)))
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))

      expect(screen.getByText('Loading issues')).toBeInTheDocument()
    })

    it('closes with x button', async () => {
      const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
      renderComponent()
      await user.click(screen.getByRole('button', {name: 'View Issues'}))
      const xButton = screen.queryAllByText('Close')[0]
      await user.click(xButton)

      expect(
        screen.queryByRole('heading', {name: 'Canvas Cartridge Importer Issues'})
      ).not.toBeInTheDocument()
    })

    it('closes with close button', async () => {
      const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
      renderComponent()
      await user.click(screen.getByRole('button', {name: 'View Issues'}))
      const closeButton = screen.queryAllByText('Close')[1]
      await user.click(closeButton)

      expect(
        screen.queryByRole('heading', {name: 'Canvas Cartridge Importer Issues'})
      ).not.toBeInTheDocument()
    })
  })
})
