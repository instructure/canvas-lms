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
import {fireEvent, render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import CreatePortfolioForm from '../CreatePortfolioForm'

describe('CreatePortfolioForm', () => {
  beforeEach(() => {
    fetchMock.restore()
  })

  it('displays form when clicking add button', () => {
    const mountNode = document.createElement('div')
    const {getByTestId, getByText} = render(
      <React.Fragment>
        <div ref={node => node && node.appendChild(mountNode)} />
        <CreatePortfolioForm formMount={mountNode} />
      </React.Fragment>,
    )

    getByTestId('add-portfolio-button').click()
    expect(getByText('Portfolio name')).toBeVisible()
    expect(getByText('Mark as Public')).toBeVisible()
  })

  it('sets focus and shows error if name is blank', () => {
    const mountNode = document.createElement('div')
    const {getByTestId, getByText} = render(
      <React.Fragment>
        <div ref={node => node && node.appendChild(mountNode)} />
        <CreatePortfolioForm formMount={mountNode} />
      </React.Fragment>,
    )

    getByTestId('add-portfolio-button').click()
    const textInput = getByTestId('portfolio-name-field')
    const saveButton = getByText('Submit')
    saveButton.click()
    waitFor(() => {
      expect(textInput).toHaveFocus()
      expect(getByText('Name is required.')).toBeInTheDocument()
    })
  })

  it('makes POST request when submitting', async () => {
    const mountNode = document.createElement('div')
    const {getByTestId, getByText} = render(
      <React.Fragment>
        <div ref={node => node && node.appendChild(mountNode)} />
        <CreatePortfolioForm formMount={mountNode} />
      </React.Fragment>,
    )

    const path = encodeURI('/eportfolios?include_redirect=true')
    fetchMock.post(path, {status: 200})

    getByTestId('add-portfolio-button').click()
    const textInput = getByTestId('portfolio-name-field')
    fireEvent.change(textInput, {target: {value: 'Test Portfolio'}})
    const saveButton = getByText('Submit')
    saveButton.click()
    await waitFor(() => expect(fetchMock.called(path, 'POST')).toBe(true))
  })

  it('hides form when cancelling ', () => {
    const mountNode = document.createElement('div')
    const {getByTestId, getByText} = render(
      <React.Fragment>
        <div ref={node => node && node.appendChild(mountNode)} />
        <CreatePortfolioForm formMount={mountNode} />
      </React.Fragment>,
    )

    getByTestId('add-portfolio-button').click()
    const nameInput = getByText('Portfolio name')
    const publicCheck = getByText('Mark as Public')
    getByText('Cancel').click()
    expect(nameInput).not.toBeVisible()
    expect(publicCheck).not.toBeVisible()
  })
})
