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

import React from 'react'
import ReactDOM from 'react-dom'
import ready from '@instructure/ready'
import DeprecationAlert from './react/DeprecationAlert'
import DeprecationModal from './react/DeprecationModal'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

declare const ENV: GlobalEnv & {
  USER_NOTES_DEPRECATION: {deprecation_date: string; suppress_notice: boolean}
}

const PROPS = {
  deprecationDate: ENV.USER_NOTES_DEPRECATION.deprecation_date,
  timezone: ENV.TIMEZONE,
}

ready(() => {
  const content = document.getElementById('content')
  if (content) {
    const alertContainer = document.createElement('div')
    const modalContainer = document.createElement('div')
    content.prepend(alertContainer)
    content.appendChild(modalContainer)
    ReactDOM.render(<DeprecationAlert {...PROPS} />, alertContainer)
    if (!ENV.USER_NOTES_DEPRECATION.suppress_notice) {
      ReactDOM.render(<DeprecationModal {...PROPS} />, modalContainer)
    }
  }
})
