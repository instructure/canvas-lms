// @vitest-environment jsdom
/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import $ from 'jquery'
import sinon from 'sinon'
import {setupSubmitHandler} from '../reuploadSubmissionsHelper'

describe('setupSubmitHandler', () => {
  const formId = 're_upload_submissions_form'
  let formSubmit
  let fixture
  let sandbox

  beforeEach(() => {
    sandbox = sinon.createSandbox()
    sandbox.stub($.fn, 'formSubmit')
    fixture = document.createElement('div')
    document.body.appendChild(fixture)
    fixture.innerHTML = `<form id="${formId}" enctype="multipart/form-data"><input type="file" name="submissions_zip"><button type="submit">Upload Files</button></form>`

    const dummySubmit = event => {
      event.preventDefault()
      event.stopPropagation()
    }
    formSubmit = sandbox.stub()
    document.getElementById(formId).addEventListener('submit', formSubmit.callsFake(dummySubmit))
  })

  afterEach(() => {
    fixture.remove()
    sandbox.restore()
  })

  it('sets up the handler by calling $.fn.formSubmit', () => {
    setupSubmitHandler(formId, 'user_1')
    expect($.fn.formSubmit.callCount).toEqual(1)
  })

  describe('beforeSubmit', () => {
    let beforeSubmit

    beforeEach(() => {
      beforeSubmit = setupSubmitHandler(formId, 'user_1').beforeSubmit.bind($(`#${formId}`))
    })

    it('returns false if a file has not been selected', () => {
      const isValid = beforeSubmit({submissions_zip: null})
      expect(isValid).toEqual(false)
    })

    it('returns false if the selected file is not a zip file', () => {
      const isValid = beforeSubmit({submissions_zip: 'submissions.png'})
      expect(isValid).toEqual(false)
    })

    it('returns true if the selected file is a zip file', () => {
      const isValid = beforeSubmit({submissions_zip: 'submissions.zip'})
      expect(isValid).toEqual(true)
    })

    it('disables the submit button if the file is valid', () => {
      beforeSubmit({submissions_zip: 'submissions.zip'})
      const submitButton = document.querySelector('button[type="submit"]')
      expect(submitButton.disabled).toEqual(true)
    })

    it('does not disable the submit button if the file is invalid', () => {
      beforeSubmit({submissions_zip: null})
      const submitButton = document.querySelector('button[type="submit"]')
      expect(submitButton.disabled).toEqual(false)
    })

    it('changes submit button text to "Uploading..." if the file is valid', () => {
      beforeSubmit({submissions_zip: 'submissions.zip'})
      const submitButton = document.querySelector('button[type="submit"]')
      expect(submitButton.textContent).toEqual('Uploading...')
    })
  })

  describe('error', () => {
    let errorFn

    beforeEach(() => {
      errorFn = setupSubmitHandler(formId, 'user_1').error.bind($(`#${formId}`))
      const submitButton = $('button[type="submit"]')
      submitButton.prop('disabled', true)
      submitButton.text('Uploading...')
    })

    it('re-enables the submit button', () => {
      errorFn()
      const submitButton = document.querySelector('button[type="submit"]')
      expect(submitButton.disabled).toEqual(false)
    })

    it('restores the original text on the submit button', () => {
      errorFn()
      const submitButton = document.querySelector('button[type="submit"]')
      expect(submitButton.textContent).toEqual('Upload Files')
    })
  })

  describe('errorFormatter', () => {
    let errorFormatter

    beforeEach(() => {
      errorFormatter = setupSubmitHandler(formId, 'user_1').errorFormatter
    })

    it('returns a generic error message', () => {
      const {errorMessage} = errorFormatter(new Error('oopsies'))
      expect(errorMessage).toEqual('Upload error. Please try again.')
    })
  })

  describe('success', () => {
    let attachment
    let success

    beforeEach(() => {
      attachment = {id: '729'}
      success = setupSubmitHandler(formId, 'user_1').success
    })

    it('adds the attachment ID to the form', () => {
      success(attachment)
      const input = document.querySelector('input[name="attachment_id"]')
      expect(input.value).toEqual(attachment.id)
    })

    it('submits the form', () => {
      success(attachment)
      expect(formSubmit.callCount).toEqual(1)
    })

    it('removes the file input', () => {
      success(attachment)
      const input = document.querySelectorAll('input[name="submissions_zip"]')
      expect(input.length).toEqual(0)
    })

    it('removes the multipart enctype', () => {
      success(attachment)
      const enctype = document.getElementById(formId).getAttribute('enctype')
      expect(enctype).toEqual(null)
    })
  })
})
