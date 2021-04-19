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

import React from 'react'
import ReactDOM from 'react-dom'
import ready from '@instructure/ready'
import {QRMobileLogin} from './react/QRMobileLogin'

ready(() => {
  let container

  container = document.createElement('div')
  container.setAttribute('id', 'qr_login_container')
  const content = document.querySelector('#content')
  content.appendChild(container)
  container = document.querySelector('#qr_login_container')

  if (container) {
    ReactDOM.render(<QRMobileLogin withWarning />, container)
  }
})
