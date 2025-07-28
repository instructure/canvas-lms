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
import ReactDOM from 'react-dom/client'
import ready from '@instructure/ready'
import App from './react/App'

ready(() => {
  const root = document.getElementById('instui_course_copy')
  if (root) {
    const courseId: string = ENV.current_context?.id || ''
    const rootAccountId: string = ENV.DOMAIN_ROOT_ACCOUNT_ID
    const accountId: string = ENV.ACCOUNT_ID
    const canImportAsNewQuizzes: boolean = ENV.NEW_QUIZZES_MIGRATION || false
    const userTimeZone: string | undefined = ENV.TIMEZONE
    const courseTimeZone: string | undefined = ENV.CONTEXT_TIMEZONE

    if (!courseId) {
      throw Error('Course id is not provided!')
    }

    if (!rootAccountId) {
      throw Error('Account id is not provided!')
    }

    ReactDOM.createRoot(root).render(
      <App
        courseId={courseId}
        rootAccountId={rootAccountId}
        accountId={accountId}
        userTimeZone={userTimeZone}
        courseTimeZone={courseTimeZone}
        canImportAsNewQuizzes={canImportAsNewQuizzes}
      />,
    )
  }
})
