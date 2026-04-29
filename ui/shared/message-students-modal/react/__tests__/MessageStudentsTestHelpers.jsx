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
import {render} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import MessageStudents from '../index'

export const defaultProps = {
  contextCode: 'course_1',
  title: 'Send a message',
  recipients: [{id: '1', displayName: 'John Doe', email: 'john@example.com'}],
  onRequestClose: () => {},
}

export const createServer = () =>
  setupServer(
    http.post('/api/v1/conversations', () => {
      return HttpResponse.json({success: true}, {status: 200})
    }),
  )

export const renderMessageStudents = (props = {}) => {
  return render(<MessageStudents {...defaultProps} {...props} />)
}
