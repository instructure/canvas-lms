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

import getCookie from '@instructure/get-cookie'

export function submitHtmlForm(path: string, method: string, md5?: string): void {
  // Create and submit an actual HTML form to ensure proper redirect handling
  // and preservation of flash messages set via addFlashNoticeForNextPage
  const form = document.createElement('form')
  form.action = path
  form.method = 'POST'
  form.style.display = 'none'

  // Add CSRF token
  const csrfInput = document.createElement('input')
  csrfInput.type = 'hidden'
  csrfInput.name = 'authenticity_token'
  csrfInput.value = getCookie('_csrf_token') || ''
  form.appendChild(csrfInput)

  // Add method override for non-POST methods (Rails convention)
  if (method !== 'POST') {
    const methodInput = document.createElement('input')
    methodInput.type = 'hidden'
    methodInput.name = '_method'
    methodInput.value = method
    form.appendChild(methodInput)
  }

  // Add optional md5 parameter
  if (typeof md5 !== 'undefined') {
    const md5Input = document.createElement('input')
    md5Input.type = 'hidden'
    md5Input.name = 'brand_config_md5'
    md5Input.value = md5
    form.appendChild(md5Input)
  }

  document.body.appendChild(form)
  form.submit()
}
