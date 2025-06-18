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

import {Model} from '@canvas/backbone'
import ValidatedFormView from '../ValidatedFormView'
import $ from 'jquery'
import 'jquery-migrate'
import {http, HttpResponse} from 'msw'
import {mswServer} from '../../../../msw/mswServer'
import fakeENV from '@canvas/test-utils/fakeENV'

class MyForm extends ValidatedFormView {
  fieldSelectors = {last_name: '[name="user[last_name]"]'}

  initialize() {
    super.initialize(...arguments)
    this.model = new Model()
    this.model.url = '/fail'
    return this.render()
  }

  template() {
    return `
      <input type="text" name="first_name" value="123">
      <input type="text" name="user[last_name]" value="123">
      <button type="submit">submit</button>
      `
  }
}

const server = mswServer([
  http.post('/fail', () => {
    return new HttpResponse('', {status: 200})
  }),
])

describe('ValidatedFormView', () => {
  let form

  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    fakeENV.setup()
    jest.useFakeTimers()
    document.body.innerHTML = '<div id="fixtures"></div>'
    form = new MyForm()
    $('#fixtures').append(form.el)
  })

  afterEach(() => {
    form.$el.remove()
    $('.errorBox').remove()
    jest.advanceTimersByTime(250) // tick past errorBox animations
    jest.useRealTimers()
    document.body.innerHTML = ''
    fakeENV.teardown()
  })

  it('disables inputs while loading', () => {
    expect(form.$(':disabled')).toHaveLength(0)

    form.on('submit', () => {
      jest.advanceTimersByTime(20) // disableWhileLoading does its thing in a setTimeout
      expect(form.$(':disabled')).toHaveLength(3)
    })

    form.submit()
  })

  it('delegates submit to saveFormData', () => {
    const saveFormDataSpy = jest.spyOn(form, 'saveFormData')
    form.submit()
    expect(saveFormDataSpy).toHaveBeenCalled()
  })

  it('calls validateBeforeSave during submit', () => {
    const validateBeforeSaveSpy = jest.spyOn(form, 'validateBeforeSave')
    form.submit()
    expect(validateBeforeSaveSpy).toHaveBeenCalled()
  })

  it('calls hideErrors during submit', () => {
    const hideErrorsSpy = jest.spyOn(form, 'hideErrors')
    form.submit()
    expect(hideErrorsSpy).toHaveBeenCalled()
  })

  it('delegates validateBeforeSave to validateFormData by default', () => {
    const validateFormDataSpy = jest.spyOn(form, 'validateFormData')
    form.validateBeforeSave({})
    expect(validateFormDataSpy).toHaveBeenCalled()
  })

  it('delegates validate to validateFormData', () => {
    const validateFormDataSpy = jest.spyOn(form, 'validateFormData')
    form.validate()
    expect(validateFormDataSpy).toHaveBeenCalled()
  })

  it('calls hideErrors during validate with and without errors', () => {
    const hideErrorsSpy = jest.spyOn(form, 'hideErrors')
    jest
      .spyOn(form, 'validateFormData')
      .mockReturnValueOnce({})
      .mockReturnValueOnce({
        errors: [
          {
            type: 'required',
            message: 'REQUIRED!',
          },
        ],
      })

    form.validate()
    expect(hideErrorsSpy).toHaveBeenCalled()

    hideErrorsSpy.mockClear()
    form.validate()
    expect(hideErrorsSpy).toHaveBeenCalled()
  })

  it('calls showErrors during validate with and without errors', () => {
    const showErrorsSpy = jest.spyOn(form, 'showErrors')
    jest
      .spyOn(form, 'validateFormData')
      .mockReturnValueOnce({})
      .mockReturnValueOnce({
        errors: [
          {
            type: 'required',
            message: 'REQUIRED!',
          },
        ],
      })

    form.validate()
    expect(showErrorsSpy).toHaveBeenCalled()

    showErrorsSpy.mockClear()
    form.validate()
    expect(showErrorsSpy).toHaveBeenCalled()
  })

  describe('RCE Integration', () => {
    beforeEach(() => {
      fakeENV.setup({use_rce_enhancements: true})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('calls the sendFunc to determine if RCE is ready', () => {
      const fakeSendFunc = jest.fn().mockReturnValue(true)
      const textArea = $('<textarea data-rich_text="true"></textarea>')
      form.$el.append(textArea)

      form.submit(null, fakeSendFunc)

      expect(fakeSendFunc).toHaveBeenCalledWith(
        expect.objectContaining({0: textArea[0]}),
        'checkReadyToGetCode',
        window.confirm,
      )
    })

    it('ends execution if sendFunc returns false', () => {
      const validateFormDataSpy = jest.spyOn(form, 'validateFormData')
      const fakeSendFunc = jest.fn().mockReturnValue(false)
      const textArea = $('<textarea data-rich_text="true"></textarea>')
      form.$el.append(textArea)

      form.submit(null, fakeSendFunc)

      expect(validateFormDataSpy).not.toHaveBeenCalled()
    })
  })
})
