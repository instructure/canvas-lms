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
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as createI18nScope} from '@canvas/i18n'
import {loadSignupDialog} from '@canvas/signup-dialog'
import ready from '@instructure/ready'

const I18n = createI18nScope('pseudonyms_mobile_login')

const eventToBindTo = 'click' as const

interface AjaxOptions {
  type: string
  url: string
  data?: string
  headers?: Record<string, string>
  contentType?: string
  context?: unknown
  success?: (responseText: string, status: string, xhr: XMLHttpRequest) => void
  error?: (xhr: XMLHttpRequest, status: string) => void
  complete?: (xhr: XMLHttpRequest, status: string) => void
}

ready(() => {
  function setupParentSignup(): void {
    const element = document.querySelector<HTMLAnchorElement>('#coenrollment_link a')
    if (element) {
      element.addEventListener(eventToBindTo, (e: MouseEvent) => {
        e.preventDefault()
        const template = element.getAttribute('data-template')
        const path = element.getAttribute('data-path')
        loadSignupDialog
          .then(
            (
              signupDialog: (template: string | null, title: string, path: string | null) => void,
            ) => {
              signupDialog(template, I18n.t('parent_signup', 'Parent Signup'), path)
            },
          )
          .catch((error: unknown) => {
            throw new Error('Error loading signup dialog: ' + String(error))
          })
      })
    }
  }

  function setupForgotPassword(): void {
    const $front_back_container = document.querySelector<HTMLElement>('#f1_container')
    const $flip_to_back = document.querySelector<HTMLElement>('.flip-to-back')
    const $forgot_password_form = document.querySelector<HTMLFormElement>('#forgot_password_form')
    const uniqueIdInput = document.querySelector<HTMLInputElement>(
      '#pseudonym_session_unique_id_forgot',
    )

    if (!$front_back_container || !$forgot_password_form || !uniqueIdInput) {
      return
    }

    if ($flip_to_back) {
      $flip_to_back.addEventListener(eventToBindTo, (event: MouseEvent) => {
        event.preventDefault()
        addClass($front_back_container, 'flipped')
        setFocus(uniqueIdInput)
      })
    }

    const $flip_to_front = document.querySelector<HTMLElement>('.flip-to-front')
    if ($flip_to_front) {
      $flip_to_front.addEventListener(eventToBindTo, (event: MouseEvent) => {
        event.preventDefault()
        removeClass($front_back_container, 'flipped')
      })
    }

    $forgot_password_form.addEventListener('submit', (event: SubmitEvent) => {
      const $button = $forgot_password_form.querySelector<HTMLButtonElement>(
        '.request-password-button',
      )
      const $authenticityToken = $forgot_password_form.querySelector<HTMLInputElement>(
        'input[name=authenticity_token]',
      )

      if (!$button || !$authenticityToken) {
        return
      }

      const uniqueIdValue = uniqueIdInput.value.trim()

      if (!uniqueIdValue) {
        return
      }

      $button.disabled = true
      const textWhileLoading = $button.getAttribute('data-text-while-loading')
      if (textWhileLoading) {
        $button.textContent = textWhileLoading
      }
      event.preventDefault()
      ajax({
        type: 'POST',
        url: '/forgot_password',
        data: `authenticity_token=${encodeURIComponent($authenticityToken.value)}
            &pseudonym_session%5Bunique_id_forgot%5D=${encodeURIComponent(uniqueIdValue)}`,
        success() {
          $button.disabled = false
          const textWhenLoaded = $button.getAttribute('data-text-when-loaded')
          if (textWhenLoaded) {
            $button.textContent = textWhenLoaded
          }
        },
        error() {
          const textOnError = $button.getAttribute('data-text-on-error')
          if (textOnError) {
            $button.textContent = textOnError
          }
        },
      })
    })
  }

  function setFocus(element: HTMLElement): void {
    element.focus()
  }

  function addClass(element: HTMLElement, name: string): void {
    removeClass(element, name)
    element.className += ` ${name}`
  }

  function removeClass(element: HTMLElement, name: string): void {
    const regex = new RegExp(`(^|\\s)${name}(\\s|$)`)
    element.className = element.className.replace(regex, '')
  }

  function ajax(options: AjaxOptions): XMLHttpRequest {
    const xhr = new window.XMLHttpRequest()
    options.headers = options.headers || {}
    options.headers['X-Requested-With'] = 'XMLHttpRequest'
    if (options.data && !options.contentType) {
      options.contentType = 'application/x-www-form-urlencoded'
    }
    if (options.contentType) {
      options.headers['Content-Type'] = options.contentType
    }

    xhr.onreadystatechange = () => {
      if (xhr.readyState === 4) {
        let error = false
        if ((xhr.status >= 200 && xhr.status < 300) || xhr.status === 0) {
          if (options.success) {
            options.success.call(options.context, xhr.responseText, 'success', xhr)
          }
        } else {
          error = true
          if (options.error) {
            options.error.call(options.context, xhr, 'error')
          }
        }
        if (options.complete) {
          options.complete.call(options.context, xhr, error ? 'error' : 'success')
        }
      }
    }

    xhr.open(options.type, options.url, true)
    Object.keys(options.headers).forEach(name => xhr.setRequestHeader(name, options.headers![name]))
    xhr.send(options.data)
    return xhr
  }

  setupForgotPassword()
  setupParentSignup()
})
