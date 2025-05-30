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

import {render, waitFor} from '@testing-library/react'
import SisImportForm from '../SisImportForm'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import fakeENV from '@canvas/test-utils/fakeENV'
import userEvent, {UserEvent} from '@testing-library/user-event'
import fetchMock from 'fetch-mock'

const ACCOUNT_ID = '100'
const SIS_IMPORT_URI = `/sis_imports`
const TERMS_API_URI = `/api/v1/accounts/${ACCOUNT_ID}/terms`

const uploadFile = async (user: UserEvent, fileDrop: HTMLElement) => {
  const file = new File(['users'], 'users.csv', {type: 'file/csv'})
  await user.upload(fileDrop, file)
  return file
}

const enrollmentTerms = {enrollment_terms: [{id: '1', name: 'Term 1'}]}

describe('SisImportForm', () => {
  let queryClient: QueryClient

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })
    fakeENV.setup({ACCOUNT_ID})

    // Mock the terms API endpoint
    fetchMock.get(`${TERMS_API_URI}?per_page=100&page=1`, {
      body: enrollmentTerms,
      headers: {
        Link: '<>; rel="current"',
      },
    })
  })

  afterEach(() => {
    fetchMock.restore()
    queryClient.clear()
    fakeENV.teardown()
  })

  const renderWithClient = (ui: React.ReactElement) => {
    return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
  }

  it('should render checkboxes and descriptions', () => {
    const {queryByText, queryByTestId, getByTestId, getByText} = renderWithClient(
      <SisImportForm onSuccess={jest.fn()} />,
    )
    expect(getByText('Choose a file to import')).toBeInTheDocument()

    // batch mode
    expect(getByTestId('batch_mode')).toBeInTheDocument()

    // term select
    expect(queryByTestId('term_select')).toBeNull()

    // override sis
    expect(getByTestId('override_sis_stickiness')).toBeInTheDocument()
    expect(getByText(/this SIS import will override UI changes/)).toBeInTheDocument()

    // process as ui
    expect(queryByTestId('add_sis_stickiness')).toBeNull()
    expect(queryByText(/processed as if they are UI changes/)).toBeNull()

    // clear as ui
    expect(queryByTestId('clear_sis_stickiness')).toBeNull()
    expect(queryByText(/changed in future non-overriding SIS imports/)).toBeNull()
  })

  it('should show term select if full batch checked', async () => {
    const user = userEvent.setup()
    const {getByTestId, findByText, findByTestId} = renderWithClient(
      <SisImportForm onSuccess={jest.fn()} />,
    )

    await user.click(getByTestId('batch_mode'))

    // Use findByText instead of getByText to wait for the async rendering
    const warningText = await findByText(/this will delete everything for this term/)
    expect(warningText).toBeInTheDocument()

    const termSelect = await findByTestId('term_select')
    expect(termSelect).toBeInTheDocument()
  })

  it('should show additional checkboxes if override sis', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = renderWithClient(<SisImportForm onSuccess={jest.fn()} />)

    await user.click(getByTestId('override_sis_stickiness'))
    expect(getByTestId('add_sis_stickiness')).toBeInTheDocument()
    expect(getByText(/processed as if they are UI changes/)).toBeInTheDocument()

    expect(getByTestId('clear_sis_stickiness')).toBeInTheDocument()
    expect(getByText(/changed in future non-overriding SIS imports/)).toBeInTheDocument()
  })

  it('disables override checkboxes based on check status', async () => {
    const user = userEvent.setup()
    const {getByTestId} = renderWithClient(<SisImportForm onSuccess={jest.fn()} />)

    await user.click(getByTestId('override_sis_stickiness'))
    const addCheck = getByTestId('add_sis_stickiness')
    const clearCheck = getByTestId('clear_sis_stickiness')

    await user.click(clearCheck)
    expect(addCheck).toBeDisabled()

    await user.click(clearCheck)
    expect(addCheck).not.toBeDisabled()

    await user.click(addCheck)
    expect(clearCheck).toBeDisabled()

    await user.click(addCheck)
    expect(clearCheck).not.toBeDisabled()
  })

  it('calls onSuccess with data on submit', async () => {
    const onSuccess = jest.fn()
    const user = userEvent.setup()
    fetchMock.post(SIS_IMPORT_URI, 200)
    const {getByText, getByTestId} = renderWithClient(<SisImportForm onSuccess={onSuccess} />)

    const file = await uploadFile(user, getByTestId('file_drop'))

    getByText('Process Data').click()
    await waitFor(() => expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(true))
    expect(onSuccess).toHaveBeenCalled()

    // validate body is accurate
    const fetchOptions = fetchMock.lastCall()?.[1] || {}
    const formData = fetchOptions.body as FormData
    // file.toString() is just [object File], but it confirms a file is sent
    expect(formData.get('attachment')).toBe(file.toString())
    expect(formData.get('batch_mode')).toBe('false')
    expect(formData.get('override_sis_stickiness')).toBe('false')
  })

  describe('opens confirmation modal', () => {
    it('if full batch checked', async () => {
      const user = userEvent.setup()
      const {getByTestId, getByText, findByTestId} = renderWithClient(
        <SisImportForm onSuccess={jest.fn()} />,
      )
      await uploadFile(user, getByTestId('file_drop'))
      await user.click(getByTestId('batch_mode'))

      // Wait for the term select to appear
      await findByTestId('term_select')

      getByText('Process Data').click()
      expect(getByText('Confirm Changes')).toBeInTheDocument()
    })

    it('calls onSuccess if confirmed', async () => {
      const onSuccess = jest.fn()
      const user = userEvent.setup()
      fetchMock.post(SIS_IMPORT_URI, 200)
      const {getByText, getByTestId, findByTestId} = renderWithClient(
        <SisImportForm onSuccess={onSuccess} />,
      )
      await uploadFile(user, getByTestId('file_drop'))
      await user.click(getByTestId('batch_mode'))

      // Wait for the term select to appear
      await findByTestId('term_select')

      getByText('Process Data').click()
      getByText('Confirm').click()
      await waitFor(() => expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(true))
      expect(onSuccess).toHaveBeenCalled()

      // validate body is accurate
      const fetchOptions = fetchMock.lastCall()?.[1] || {}
      const formData = fetchOptions.body as FormData
      expect(formData.get('batch_mode')).toBe('true')
      expect(formData.get('batch_mode_term_id')).toBe('1')
    })

    it('does not call onSuccess if cancelled', async () => {
      const onSuccess = jest.fn()
      const user = userEvent.setup()
      const {getByText, getByTestId, queryByText, findByTestId} = renderWithClient(
        <SisImportForm onSuccess={onSuccess} />,
      )
      await uploadFile(user, getByTestId('file_drop'))
      await user.click(getByTestId('batch_mode'))

      // Wait for the term select to appear
      await findByTestId('term_select')

      getByText('Process Data').click()
      getByText('Cancel').click()
      await waitFor(() => {
        expect(queryByText('Confirm Changes')).toBeNull()
        expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(false)
        expect(onSuccess).not.toHaveBeenCalled()
      })
    })
  })
})
