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
import RunReportForm from '../RunReportForm'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import fakeENV from '@canvas/test-utils/fakeENV'

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

const innerHtml3 = `<form>
  <table>
    <tr>
      <td>
        Updated after:
        <input type="text" name="parameters[updated_after]" class="datetime_field" />
      </td>
    </tr>
  </table>
  </form>`

const innerHtml4 = `<form>
  <table>
    <tr>
      <td>
        <input type="checkbox" data-testid="show_text" id="show_text" />
      </td>
    </tr>
    <tr>
      <td>
        <p id="invisible_text">This text is visible</p>
      </td>
    </tr>
  </table>
  </form>

  <script>
    document.getElementById('invisible_text').style.display = 'none';
    document.getElementById('show_text').onclick = function(){
        document.getElementById('invisible_text').style.display = 'block';
    };
</script>`

const props = {
  formHTML: innerHtml1,
  path: '/api/fake_post',
  reportName: 'test_report_csv',
  closeModal: jest.fn(),
  onSuccess: jest.fn(),
  onRender: jest.fn(),
}

describe('RunReportForm', () => {
  beforeEach(() => {
    fakeENV.setup({
      TIMEZONE: 'America/Los_Angeles',
      LOCALE: 'en',
    })
  })
  afterEach(() => {
    fetchMock.restore()
    fakeENV.teardown()
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

  it('sets up date/time pickers', async () => {
    const user = userEvent.setup()
    fetchMock.post(props.path, {
      status: 200,
    })
    const {getByTestId} = render(<RunReportForm {...props} formHTML={innerHtml3} />)

    const dateInput = getByTestId('parameters[updated_after]')
    expect(dateInput).toBeInTheDocument()
    fireEvent.input(dateInput, {target: {value: 'May 1, 2025'}})
    fireEvent.blur(dateInput)

    const submitButton = getByTestId('run-report')
    await user.click(submitButton)

    await waitFor(() => {
      expect(props.onSuccess).toHaveBeenCalled()
      expect(fetchMock.called(props.path, 'POST')).toBeTruthy()
      const request = fetchMock.lastOptions()
      const formData = request?.body as FormData
      expect(request?.method).toBe('POST')
      expect(formData.get('parameters[updated_after]')).toBe('2025-05-01T07:00:00.000Z')
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

  it('executes script tags', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = render(<RunReportForm {...props} formHTML={innerHtml4} />)

    expect(getByText('This text is visible').getAttribute('style')).toBe('display: none;')
    const checkbox = getByTestId('show_text')
    await user.click(checkbox)
    expect(getByText('This text is visible').getAttribute('style')).toBe('display: block;')
  })
})
