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
import RunReportForm from '../account_reports/RunReportForm'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

const innerHtml = `<form>
  <h1>Test HTML</h1>
  <input type="checkbox" name="parameter[checkbox]" data-testid="checkbox" />
  <select name="parameter[select]" data-testid="select">
      <option value="option_1" data-testid="option_1">Option 1</option>
      <option value="option_2" data-testid="option_2">Option 2</option>
  </select>
  </form>`

const props = {
  formHTML: innerHtml,
  path: '/api/fake_post',
  reportName: 'test_report_csv',
  closeModal: jest.fn(),
  onSuccess: jest.fn(),
  onRender: jest.fn(),
}

// usually, we swap the jQuery date input for the CanvasDatePicker
// but since this is a jest test, that won't happen
// so we won't test date input (see selenium tests for that)
describe('RunReportForm', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('render html', () => {
    const {getByText, getByTestId} = render(<RunReportForm {...props} />)

    expect(getByText('Test HTML')).toBeInTheDocument()
    expect(getByTestId('checkbox')).toBeInTheDocument()
    expect(getByTestId('select')).toBeInTheDocument()
  })

  it('makes api call with input values', async () => {
    const user = userEvent.setup()
    fetchMock.post(props.path, {
      status: 200,
    })
    const {getByTestId} = render(<RunReportForm {...props} />)

    const checkbox = getByTestId('checkbox')
    await user.click(checkbox)
    expect(checkbox).toBeChecked()

    const submitButton = getByTestId('run-report')
    await user.click(submitButton)

    await waitFor(() => {
      expect(props.onSuccess).toHaveBeenCalled()
      expect(fetchMock.called(props.path, 'POST')).toBeTruthy()
      const request = fetchMock.lastOptions()
      const formData = request?.body as FormData
      expect(request?.method).toBe('POST')
      expect(formData.get('parameter[checkbox]')).toBeTruthy()
      expect(formData.get('parameter[select]')).toBe('option_1')
    })
  })

  it('shows error message when api call fails', async () => {
    const user = userEvent.setup()
    fetchMock.post(props.path, {
      status: 500,
    })
    const {getByTestId, getAllByText} = render(<RunReportForm {...props} />)

    const submitButton = getByTestId('run-report')
    await user.click(submitButton)

    await waitFor(() => {
      expect(getAllByText('Failed to start report.')[0]).toBeInTheDocument()
    })
  })
})
