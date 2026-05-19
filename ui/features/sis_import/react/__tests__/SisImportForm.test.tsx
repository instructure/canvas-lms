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

import {render, waitFor, fireEvent} from '@testing-library/react'
import SisImportForm from '../SisImportForm'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import fakeENV from '@canvas/test-utils/fakeENV'
import userEvent, {UserEvent} from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import {vi} from 'vitest'
import {completeUpload} from '@canvas/upload-file'

// Mock the completeUpload function
vi.mock('@canvas/upload-file', () => ({
  completeUpload: vi.fn().mockResolvedValue({
    id: 456,
    filename: 'users.csv',
    display_name: 'users.csv',
  }),
}))

const ACCOUNT_ID = '100'
const SIS_IMPORT_URI = `/sis_imports`
const TERMS_API_URI = `/api/v1/accounts/${ACCOUNT_ID}/terms`

const uploadFile = async (user: UserEvent, fileDrop: HTMLElement) => {
  const file = new File(['users'], 'users.csv', {type: 'file/csv'})
  await user.upload(fileDrop, file)
  return file
}

const mockPost = (expected: {batchMode: boolean; overrideSis: boolean; termId?: string}) => {
  const {batchMode, overrideSis, termId} = expected
  fetchMock.post(SIS_IMPORT_URI, (_url, opts) => {
    const body = opts?.body

    if (typeof body !== 'string') {
      throw new Error('Expected JSON string')
    }

    const parsedBody = JSON.parse(body)

    expect(parsedBody.pre_attachment).toBeDefined() // pre_attachment should be present
    expect(parsedBody.batch_mode).toEqual(batchMode)
    expect(parsedBody.override_sis_stickiness).toEqual(overrideSis)
    if (termId) {
      expect(parsedBody.batch_mode_term_id).toEqual(termId)
    }

    // Return response with pre_attachment data for the two-step flow
    return {
      id: 123,
      workflow_state: 'created',
      data: {},
      progress: 0,
      pre_attachment: {
        upload_url: 'https://s3.example.com/upload',
        upload_params: {
          key: 'uploads/123/users.csv',
          policy: 'base64policy',
          signature: 'signature',
        },
        file_param: 'file',
      },
    }
  })
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
    fetchMock.get(`${TERMS_API_URI}?per_page=100&page=1&term_name=`, {
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
    vi.clearAllMocks()
  })

  const renderWithClient = (ui: React.ReactElement) => {
    return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
  }

  it('should render checkboxes and descriptions', () => {
    const {queryByText, queryByTestId, getByTestId, getByText} = renderWithClient(
      <SisImportForm onSuccess={vi.fn()} />,
    )
    expect(getByText('Choose a file to import')).toBeInTheDocument()

    // batch mode
    expect(getByTestId('batch_mode')).toBeInTheDocument()

    // term select
    expect(queryByTestId('full-batch-dropdown')).toBeNull()

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
      <SisImportForm onSuccess={vi.fn()} />,
    )

    await user.click(getByTestId('batch_mode'))

    // Use findByText instead of getByText to wait for the async rendering
    const warningText = await findByText(/this will delete everything for this term/)
    expect(warningText).toBeInTheDocument()

    const termSelect = await findByTestId('full-batch-dropdown')
    expect(termSelect).toBeInTheDocument()
  })

  it('should show additional checkboxes if override sis', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = renderWithClient(<SisImportForm onSuccess={vi.fn()} />)

    await user.click(getByTestId('override_sis_stickiness'))
    expect(getByTestId('add_sis_stickiness')).toBeInTheDocument()
    expect(getByText(/processed as if they are UI changes/)).toBeInTheDocument()

    expect(getByTestId('clear_sis_stickiness')).toBeInTheDocument()
    expect(getByText(/changed in future non-overriding SIS imports/)).toBeInTheDocument()
  })

  it('disables override checkboxes based on check status', async () => {
    const user = userEvent.setup()
    const {getByTestId} = renderWithClient(<SisImportForm onSuccess={vi.fn()} />)

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

  it('calls onSuccess with data on submit and handles two-step upload', async () => {
    const onSuccess = vi.fn()
    const user = userEvent.setup()
    mockPost({batchMode: false, overrideSis: false})
    vi.mocked(completeUpload).mockClear()

    const {getByText, getByTestId} = renderWithClient(<SisImportForm onSuccess={onSuccess} />)

    const file = await uploadFile(user, getByTestId('file_drop'))

    getByText('Process Data').click()
    await waitFor(() => expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(true))

    // Verify completeUpload was called with the correct parameters
    expect(completeUpload).toHaveBeenCalledWith(
      {
        upload_url: 'https://s3.example.com/upload',
        upload_params: {
          key: 'uploads/123/users.csv',
          policy: 'base64policy',
          signature: 'signature',
        },
        file_param: 'file',
      },
      file,
      expect.objectContaining({
        onProgress: expect.any(Function),
      }),
    )

    await waitFor(() => expect(onSuccess).toHaveBeenCalled())

    // Verify onSuccess was called with the SIS import data
    const sisImportData = onSuccess.mock.calls[0][0]
    expect(sisImportData).toEqual(
      expect.objectContaining({
        id: 123,
        workflow_state: 'created',
        data: {},
        progress: 0,
      }),
    )
  })

  describe('site admin confirmation modal', () => {
    const ACCOUNT_NAME = 'Stride Academy'

    describe('when SHOW_SITE_ADMIN_CONFIRMATION is true', () => {
      beforeEach(() => {
        fakeENV.teardown()
        fakeENV.setup({
          ACCOUNT_ID,
          SHOW_SITE_ADMIN_CONFIRMATION: true,
          current_context: {name: ACCOUNT_NAME},
        })
      })

      it('shows modal on submit', async () => {
        const user = userEvent.setup()
        const {getByTestId, getByText} = renderWithClient(
          <SisImportForm onSuccess={vi.fn()} />,
        )
        await uploadFile(user, getByTestId('file_drop'))

        getByText('Process Data').click()
        expect(getByText('Confirm SIS Import')).toBeInTheDocument()
        expect(getByText(`Account: ${ACCOUNT_NAME}`)).toBeInTheDocument()
      })

      it('proceeds with import after typing correct account name', async () => {
        const onSuccess = vi.fn()
        const user = userEvent.setup()
        mockPost({batchMode: false, overrideSis: false})
        const {getByTestId, getByText} = renderWithClient(
          <SisImportForm onSuccess={onSuccess} />,
        )
        await uploadFile(user, getByTestId('file_drop'))

        getByText('Process Data').click()
        // Use fireEvent.change instead of user.type to avoid InstUI Modal
        // focus management conflict with the space in the account name.
        fireEvent.change(getByTestId('site-admin-confirm-input'), {target: {value: ACCOUNT_NAME}})
        await user.click(getByTestId('site-admin-confirm-btn'))

        await waitFor(() => expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(true))
        expect(onSuccess).toHaveBeenCalled()
      })

      it('does not proceed when cancelled', async () => {
        const onSuccess = vi.fn()
        const user = userEvent.setup()
        const {getByTestId, getByText, queryByText} = renderWithClient(
          <SisImportForm onSuccess={onSuccess} />,
        )
        await uploadFile(user, getByTestId('file_drop'))

        getByText('Process Data').click()
        await user.click(getByTestId('site-admin-cancel-btn'))

        await waitFor(() => {
          expect(queryByText('Confirm SIS Import')).toBeNull()
          expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(false)
          expect(onSuccess).not.toHaveBeenCalled()
        })
      })

      it('shows both site admin and batch mode warnings in one modal when both apply', async () => {
        const onSuccess = vi.fn()
        const user = userEvent.setup()
        mockPost({batchMode: true, overrideSis: false, termId: '1'})
        const {getByTestId, getByText, getAllByText, findByTestId} = renderWithClient(
          <SisImportForm onSuccess={onSuccess} />,
        )
        await uploadFile(user, getByTestId('file_drop'))
        await user.click(getByTestId('batch_mode'))
        await findByTestId('full-batch-dropdown')

        // Click submit — unified modal appears with both sections
        getByText('Process Data').click()
        expect(getByText('Confirm SIS Import')).toBeInTheDocument()
        expect(getByText(`Account: ${ACCOUNT_NAME}`)).toBeInTheDocument()
        // Warning text appears both in FullBatchDropdown and in the modal
        expect(getAllByText(/this will delete everything for this term/).length).toBeGreaterThanOrEqual(2)

        // Use fireEvent.change instead of user.type to avoid InstUI Modal
        // focus management conflict: re-rendering the batch mode Alert shifts
        // focus to a button, and the space in the account name activates it.
        fireEvent.change(getByTestId('site-admin-confirm-input'), {target: {value: ACCOUNT_NAME}})
        await user.click(getByTestId('site-admin-confirm-btn'))
        await waitFor(() => expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(true))
        expect(onSuccess).toHaveBeenCalled()
      })
    })

    it('does not show modal when SHOW_SITE_ADMIN_CONFIRMATION is false', async () => {
      const user = userEvent.setup()
      mockPost({batchMode: false, overrideSis: false})
      const onSuccess = vi.fn()
      const {getByTestId, getByText, queryByText} = renderWithClient(
        <SisImportForm onSuccess={onSuccess} />,
      )
      await uploadFile(user, getByTestId('file_drop'))

      getByText('Process Data').click()
      expect(queryByText('Confirm SIS Import')).toBeNull()
      await waitFor(() => expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(true))
    })
  })

  describe('opens confirmation modal', () => {
    it('if full batch checked', async () => {
      const user = userEvent.setup()
      const {getByTestId, getByText, getAllByText, findByTestId} = renderWithClient(
        <SisImportForm onSuccess={vi.fn()} />,
      )
      await uploadFile(user, getByTestId('file_drop'))
      await user.click(getByTestId('batch_mode'))

      // Wait for the term select to appear
      await findByTestId('full-batch-dropdown')

      getByText('Process Data').click()
      expect(getByText('Confirm SIS Import')).toBeInTheDocument()
      // Warning text appears both in FullBatchDropdown and in the modal
      expect(getAllByText(/this will delete everything for this term/).length).toBeGreaterThanOrEqual(2)
    })

    it('calls onSuccess if confirmed', async () => {
      const onSuccess = vi.fn()
      const user = userEvent.setup()
      mockPost({batchMode: true, overrideSis: false, termId: '1'})
      vi.mocked(completeUpload).mockClear()
      const {getByText, getByTestId, findByTestId} = renderWithClient(
        <SisImportForm onSuccess={onSuccess} />,
      )
      await uploadFile(user, getByTestId('file_drop'))
      await user.click(getByTestId('batch_mode'))

      // Wait for the term select to appear
      await findByTestId('full-batch-dropdown')

      getByText('Process Data').click()
      getByText('Confirm').click()
      await waitFor(() => expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(true))
      await waitFor(() => expect(onSuccess).toHaveBeenCalled())
    })

    it('does not call onSuccess if cancelled', async () => {
      const onSuccess = vi.fn()
      const user = userEvent.setup()
      const {getByText, getByTestId, queryByText, findByTestId} = renderWithClient(
        <SisImportForm onSuccess={onSuccess} />,
      )
      await uploadFile(user, getByTestId('file_drop'))
      await user.click(getByTestId('batch_mode'))

      // Wait for the term select to appear
      await findByTestId('full-batch-dropdown')

      getByText('Process Data').click()
      getByText('Cancel').click()
      await waitFor(() => {
        expect(queryByText('Confirm SIS Import')).toBeNull()
        expect(fetchMock.called(SIS_IMPORT_URI, 'POST')).toBe(false)
        expect(onSuccess).not.toHaveBeenCalled()
      })
    })
  })
})
