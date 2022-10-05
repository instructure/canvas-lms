/* Copyright (C) 2021 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import {render, fireEvent, waitFor, getByText as getByTextFromElement} from '@testing-library/react'
import CourseTemplateDetails from '../CourseTemplateDetails'

function accountFactory(n) {
  const accounts = []
  for (let i = 1; i <= n; i++) {
    accounts.push({id: String(i), name: `Account number ${i}`})
  }
  return accounts
}

const route1 = '/courses/1'
const response1 = {template: false}
const route2 = '/courses/2'
const response2 = {template: true, templated_accounts: []}
const route3 = '/courses/3'
const response3 = {template: true, templated_accounts: accountFactory(5)}
const route4 = '/courses/4'
const response4 = {template: true, templated_accounts: accountFactory(25)}

describe('CourseTemplateDetails::', () => {
  const oldEnv = window.ENV

  function setRoute(route) {
    window.ENV = {CONTEXT_BASE_URL: route}
  }

  const endpoint = base => `/api/v1${base}?include[]=templated_accounts`

  beforeAll(() => {
    fetchMock.get(endpoint(route1), response1)
    fetchMock.get(endpoint(route2), response2)
    fetchMock.get(endpoint(route3), response3)
    fetchMock.get(endpoint(route4), response4)
  })

  afterAll(() => {
    window.ENV = oldEnv
    fetchMock.restore()
  })

  describe('before the API call responds', () => {
    beforeAll(() => {
      setRoute(route1)
    })

    it('renders a spinner while loading, then the result div', async () => {
      const {getByTestId} = render(<CourseTemplateDetails isEditable={true} />)
      expect(getByTestId('loading-spinner')).toBeInTheDocument()
      await waitFor(() => expect(getByTestId('result-div')).toBeInTheDocument())
    })
  })

  describe('after the API call responds', () => {
    it('renders a disabled control if not editable', async () => {
      setRoute(route1)
      const {getByTestId} = render(<CourseTemplateDetails />)
      await waitFor(() => expect(getByTestId('result-div')).toBeInTheDocument())
      const checkbox = getByTestId('result-checkbox')
      expect(checkbox.disabled).toBe(true)
    })

    it('renders an enabled control if editable, unchecked if not a template', async () => {
      setRoute(route1)
      const {getByTestId} = render(<CourseTemplateDetails isEditable={true} />)
      await waitFor(() => expect(getByTestId('result-div')).toBeInTheDocument())
      const checkbox = getByTestId('result-checkbox')
      expect(checkbox.disabled).toBe(false)
      expect(checkbox.checked).toBe(false)
    })

    it('renders a checked box if a template, with the right message for zero associations', async () => {
      setRoute(route2)
      const {getByTestId, getByText, container} = render(
        <CourseTemplateDetails isEditable={true} />
      )
      await waitFor(() => expect(getByTestId('result-div')).toBeInTheDocument())
      const checkbox = getByTestId('result-checkbox')
      expect(checkbox.disabled).toBe(false)
      expect(checkbox.checked).toBe(true)
      expect(getByText('Not associated with any accounts')).toBeInTheDocument()
      const icon = container.querySelector('svg[name="IconInfo"]')
      expect(icon).toBeNull()
    })

    it('renders the right message for multiple associations', async () => {
      setRoute(route3)
      const {getByTestId, getByText, container} = render(
        <CourseTemplateDetails isEditable={true} />
      )
      await waitFor(() => expect(getByTestId('result-div')).toBeInTheDocument())
      const checkbox = getByTestId('result-checkbox')
      expect(checkbox.disabled).toBe(false)
      expect(checkbox.checked).toBe(true)
      expect(getByText('Associated with 5 accounts')).toBeInTheDocument()
      const icon = container.querySelector('svg[name="IconInfo"]')
      expect(icon).toBeInTheDocument()
    })

    it('renders the right message for more than ten associations', async () => {
      setRoute(route4)
      const {getByTestId, getByText} = render(<CourseTemplateDetails isEditable={true} />)
      await waitFor(() => expect(getByTestId('result-div')).toBeInTheDocument())
      expect(getByText('Associated with 10+ accounts')).toBeInTheDocument()
    })
  })

  describe('the modal', () => {
    it('displays the modal only when the link is clicked on', async () => {
      setRoute(route3)
      const {queryByTestId} = render(<CourseTemplateDetails isEditable={true} />)
      await waitFor(() => expect(queryByTestId('result-div')).toBeInTheDocument())
      expect(queryByTestId('result-modal')).toBeNull()
      const link = queryByTestId('result-n-assoc')
      fireEvent.click(link)
      await waitFor(() => expect(queryByTestId('result-modal')).toBeInTheDocument())
    })

    it('shows the right number of associated accounts in the modal', async () => {
      setRoute(route3)
      const {getByTestId} = render(<CourseTemplateDetails isEditable={true} />)
      await waitFor(() => expect(getByTestId('result-div')).toBeInTheDocument())
      const link = getByTestId('result-n-assoc')
      fireEvent.click(link)
      await waitFor(() => expect(getByTestId('result-modal')).toBeInTheDocument())
      const modal = getByTestId('result-modal')
      const listElements = modal.querySelectorAll('ul li')
      expect(listElements.length).toBe(5)
    })

    it('shows the right overflow text if more than ten associated accounts', async () => {
      setRoute(route4)
      const {getByTestId} = render(<CourseTemplateDetails isEditable={true} />)
      await waitFor(() => expect(getByTestId('result-div')).toBeInTheDocument())
      const link = getByTestId('result-n-assoc')
      fireEvent.click(link)
      await waitFor(() => expect(getByTestId('result-modal')).toBeInTheDocument())
      const modal = getByTestId('result-modal')
      const listElements = modal.querySelectorAll('ul li')
      expect(listElements.length).toBe(10)
      getByTextFromElement(modal, '(more not shown)') // should not throw
    })
  })
})
