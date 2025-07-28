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

import {useLocation, useNavigate, useNavigationType} from 'react-router-dom'
import {assignLocation} from '@canvas/util/globalUtils'
import {LOGIN_ENTRY_URL} from '../routes/routes'

export function useSafeBackNavigation() {
  const navigate = useNavigate()
  const navigationType = useNavigationType()
  const location = useLocation()

  return () => {
    if (navigationType === 'PUSH' && location.key !== 'default') {
      navigate(-1)
    } else {
      // if no meaningful history then redirect to branded login entry point
      assignLocation(LOGIN_ENTRY_URL)
    }
  }
}
