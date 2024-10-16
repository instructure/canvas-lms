/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import ready from '@instructure/ready'
import {CertUploadForm} from './react/components/CertUploadForm'
import ReactDOM from 'react-dom'

ready(() => {
  document.querySelectorAll("[id^='internal-ca-select-']").forEach(certUploadContainer => {
    const id = certUploadContainer.id.match(/internal-ca-select-(.*)$/)?.[1]

    const inputField = id && (document.querySelector(`#internal_ca_${id}`) as HTMLInputElement)

    if (inputField) ReactDOM.render(<CertUploadForm inputField={inputField} />, certUploadContainer)
  })
})
