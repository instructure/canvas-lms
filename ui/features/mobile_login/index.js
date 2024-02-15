/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import {loadSignupDialog} from '@canvas/signup-dialog'
import ready from '@instructure/ready'

const I18n = useI18nScope('pseudonyms_mobile_login')

const eventToBindTo = 'click'

ready(() => {
  setupForgotPassword()
  setupParentSignup()
})

function setupParentSignup() {
  const element = document.querySelector('#coenrollment_link a')
  if (element) {
    element.addEventListener(eventToBindTo, e => {
      e.preventDefault()
      const template = element.getAttribute('data-template')
      const path = element.getAttribute('data-path')
      loadSignupDialog
        .then(signupDialog => {
          signupDialog(template, I18n.t('parent_signup', 'Parent Signup'), path)
        })
        .catch(error => {
          throw new Error('Error loading signup dialog: ', error)
        })
    })
  }
}

function setupForgotPassword() {
  const $front_back_container = document.querySelector('#f1_container')
  const $flip_to_back = document.querySelector('.flip-to-back')
  const $forgot_password_form = document.querySelector('#forgot_password_form')
  const uniqueIdInput = document.querySelector('#pseudonym_session_unique_id_forgot')

  if ($flip_to_back) {
    $flip_to_back.addEventListener(eventToBindTo, event => {
      event.preventDefault()
      addClass($front_back_container, 'flipped')
      setFocus(uniqueIdInput)
    })
  }

  document.querySelector('.flip-to-front').addEventListener(eventToBindTo, event => {
    event.preventDefault()
    removeClass($front_back_container, 'flipped')
  })

  $forgot_password_form.addEventListener('submit', event => {
    const $button = $forgot_password_form.querySelector('.request-password-button')
    const uniqueIdValue = uniqueIdInput.value.trim()

    if (!uniqueIdValue) return false
    $button.disabled = true
    $button.textContent = $button.getAttribute('data-text-while-loading')
    event.preventDefault()
    ajax({
      type: 'POST',
      url: '/forgot_password',
      data: `authenticity_token=${encodeURIComponent(
        $forgot_password_form.querySelector('input[name=authenticity_token]').value
      )}
            &pseudonym_session%5Bunique_id_forgot%5D=${encodeURIComponent(uniqueIdValue)}`,
      success() {
        $button.disabled = false
        $button.textContent = $button.getAttribute('data-text-when-loaded')
      },
      error() {
        $button.textContent = $button.getAttribute('data-text-on-error')
      },
    })
  })
}

function setFocus(element) {
  element.focus()
}

function addClass(element, name) {
  removeClass(element, name)
  element.className += ` ${name}`
}

function removeClass(element, name) {
  const regex = new RegExp(`(^|\\s)${name}(\\s|$)`)
  element.className = element.className.replace(regex, '')
}

function ajax(options) {
  const xhr = new window.XMLHttpRequest()
  options.headers = options.headers || {}
  options.headers['X-Requested-With'] = 'XMLHttpRequest'
  if (options.data && !options.contentType)
    options.contentType = 'application/x-www-form-urlencoded'
  if (options.contentType) options.headers['Content-Type'] = options.contentType

  xhr.onreadystatechange = () => {
    if (xhr.readyState === 4) {
      let error = false
      if ((xhr.status >= 200 && xhr.status < 300) || xhr.status === 0) {
        if (options.success) options.success.call(options.context, xhr.responseText, 'success', xhr)
      } else {
        error = true
        if (options.error) options.error.call(options.context, xhr, 'error')
      }
      if (options.complete) options.complete.call(options.context, xhr, error ? 'error' : 'success')
    }
  }

  xhr.open(options.type, options.url, true)
  Object.keys(options.headers).forEach(name => xhr.setRequestHeader(name, options.headers[name]))
  xhr.send(options.data)
  return xhr
}
