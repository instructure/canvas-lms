/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import ready from '@instructure/ready'
import React from 'react'
import ReactDOM from 'react-dom'
import TermsOfServiceModal from './react/TermsOfServiceModal'

ready(() => {
  let container = document.querySelector('#terms_of_service_preview_link')
  if (container) {
    ReactDOM.render(<TermsOfServiceModal preview={true} />, container)
  } else {
    container = document.querySelectorAll('.terms_of_service_link')
    if (container.length) {
      for (let i = 0; i < container.length; i++) {
        ReactDOM.render(<TermsOfServiceModal />, container[i])
      }
    }
  }
})
