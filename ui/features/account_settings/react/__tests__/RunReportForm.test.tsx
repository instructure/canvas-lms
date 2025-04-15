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

import {fireEvent, render, waitFor} from '@testing-library/react'
import RunReportForm from '../account_reports/RunReportForm'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

const innerHtml1 = `<form>
  <h1>Test HTML</h1>
  <input type="checkbox" name="parameter[checkbox]" data-testid="checkbox" />
  <input type="checkbox" name="parameter[unchecked]" data-testid="unchecked" />
  <select name="parameter[select]" data-testid="select">
      <option value="option_1" data-testid="option_1">Option 1</option>
      <option value="option_2" data-testid="option_2">Option 2</option>
  </select>
  </form>`

const innerHtml2 = `<form>
  <h1>Test HTML</h1>
  <input type="radio" name="parameter[radio]" data-testid="radio_unchecked" value="Unchecked"/>
  <input type="radio" name="parameter[radio]" data-testid="radio_checked" value="Checked"/>
  <textarea name="parameter[textarea]" data-testid="textarea"></textarea>
  </form>`

const props = {
  formHTML: innerHtml1,
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
    expect(getByTestId('unchecked')).toBeInTheDocument()
    expect(getByTestId('select')).toBeInTheDocument()
  })

  it('makes api call with checkboxes and select', async () => {
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
      expect(formData.has('parameter[unchecked]')).toBeFalsy()
    })
  })

  // custom reports use both these field types
  it('makes api call with textarea and radio inputs', async () => {
    const user = userEvent.setup()
    fetchMock.post(props.path, {
      status: 200,
    })
    const {getByTestId} = render(<RunReportForm {...props} formHTML={innerHtml2} />)

    const radio = getByTestId('radio_checked')
    await user.click(radio)
    expect(radio).toBeChecked()

    const textarea = getByTestId('textarea')
    fireEvent.input(textarea, {target: {value: 'test text'}})
    await waitFor(() => {
      expect(textarea).toHaveValue('test text')
    })

    const submitButton = getByTestId('run-report')
    await user.click(submitButton)

    await waitFor(() => {
      expect(props.onSuccess).toHaveBeenCalled()
      expect(fetchMock.called(props.path, 'POST')).toBeTruthy()
      const request = fetchMock.lastOptions()
      const formData = request?.body as FormData
      expect(request?.method).toBe('POST')
      expect(formData.get('parameter[textarea]')).toBe('test text')
      expect(formData.get('parameter[radio]')).toBe('Checked')
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
