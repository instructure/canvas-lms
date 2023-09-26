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
import {render, act, waitFor} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {ActionButton, MigrationIssue} from '../action_button'

jest.mock('@canvas/do-fetch-api-effect')

const migrationIssues: [MigrationIssue] = [
  {
    id: 1,
    description: 'My description',
    workflow_state: 'active',
    fix_issue_html_url: 'https://mock.fix.url',
    issue_type: 'error',
    created_at: '1997-04-15T00:00:00Z',
    updated_at: '1997-04-15T00:00:00Z',
    content_migration_url: 'https://mock.migration.url',
    error_message: 'My error message',
  },
]

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

  it('renders button when issues count is greater than zero', async () => {
    const component = renderComponent()
    expect(component.getByRole('button', {name: 'View Issues'})).toBeInTheDocument()
  })

  it('does not render button when issues count is zero', async () => {
    const component = renderComponent({migration_issues_count: 0})
    expect(component.queryByRole('button', {name: 'View Issues'})).not.toBeInTheDocument()
  })

  describe('modal', () => {
    beforeEach(() => doFetchApi.mockImplementation(() => Promise.resolve({json: migrationIssues})))

    afterEach(() => jest.clearAllMocks())

    it('opens on click', () => {
      const component = renderComponent()
      const button = component.getByRole('button', {name: 'View Issues'})
      act(() => button.click())
      expect(
        component.getByRole('heading', {name: 'Canvas Cartridge Importer Issues'})
      ).toBeInTheDocument()
    })

    it('fetch issues info', () => {
      const component = renderComponent()
      const button = component.getByRole('button', {name: 'View Issues'})
      act(() => button.click())
      expect(doFetchApi).toHaveBeenCalled()
    })

    it('shows issues info', async () => {
      const component = renderComponent()
      const button = component.getByRole('button', {name: 'View Issues'})
      act(() => button.click())
      await waitFor(() => expect(component.getByRole('link')).toBeInTheDocument())
      const link = component.getByRole('link')
      expect(link).toHaveAttribute('href', 'https://mock.fix.url')
      expect(link).toHaveTextContent('My description')
    })

    it('shows alert if fetch fails', async () => {
      doFetchApi.mockImplementation(() => Promise.reject())
      const component = renderComponent()
      const button = component.getByRole('button', {name: 'View Issues'})
      act(() => button.click())
      await waitFor(() =>
        expect(component.getByText('Failed to fetch migration issues data.')).toBeInTheDocument()
      )
    })

    it('shows spinner when loading', () => {
      doFetchApi.mockImplementation(() => new Promise(resolve => setTimeout(resolve, 5000)))
      const component = renderComponent()
      const button = component.getByRole('button', {name: 'View Issues'})
      act(() => button.click())
      expect(component.getByText('Loading issues')).toBeInTheDocument()
    })

    it('closes with x button', () => {
      const component = renderComponent()
      const button = component.getByRole('button', {name: 'View Issues'})
      act(() => button.click())
      const xButton = component.queryAllByText('Close')[0]
      act(() => xButton.click())

      expect(
        component.queryByRole('heading', {name: 'Canvas Cartridge Importer Issues'})
      ).not.toBeInTheDocument()
    })

    it('closes with cancel button', () => {
      const component = renderComponent()
      const button = component.getByRole('button', {name: 'View Issues'})
      act(() => button.click())
      const cancelButton = component.getByText('Cancel')
      act(() => cancelButton.click())

      expect(
        component.queryByRole('heading', {name: 'Canvas Cartridge Importer Issues'})
      ).not.toBeInTheDocument()
    })

    it('closes with close button', () => {
      const component = renderComponent()
      const button = component.getByRole('button', {name: 'View Issues'})
      act(() => button.click())
      const closeButton = component.queryAllByText('Close')[1]
      act(() => closeButton.click())

      expect(
        component.queryByRole('heading', {name: 'Canvas Cartridge Importer Issues'})
      ).not.toBeInTheDocument()
    })
  })
})
