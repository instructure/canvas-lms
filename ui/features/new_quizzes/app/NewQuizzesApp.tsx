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

import {captureException} from '@sentry/browser'
import {useEffect, useRef} from 'react'
import {fetchNewQuizzesToken} from '../api/jwt'
import {ZAccountId} from '@canvas/lti-apps/models/AccountId'

interface RemoteModule {
  render?: (element: HTMLDivElement, props: any) => void
  unmount?: () => void
}

const accountId = ZAccountId.parse(window.ENV.ACCOUNT_ID)

export function NewQuizzesApp() {
  // Store mount point in useRef
  const mountPoint = useRef<HTMLDivElement>(null)
  const quizzesData = ENV.NEW_QUIZZES

  useEffect(() => {
    let unmount = () => {}

    async function handleLoadNewQuizzes() {
      if (!mountPoint.current || !quizzesData) {
        return
      }

      try {
        // @ts-expect-error - Module federation remote import
        const module: RemoteModule = await import('newquizzes/appInjector')

        if (typeof module.render === 'function') {
          const basename = `/courses/${quizzesData.params.custom_canvas_course_id}/assignments/${quizzesData.params.custom_canvas_assignment_id}`

          module.render(mountPoint.current, {
            ...quizzesData,
            themeOverrides: window.CANVAS_ACTIVE_BRAND_VARIABLES || null,
            basename,
            fetchToken: () => fetchNewQuizzesToken(accountId),
          })
        } else {
          captureException(new Error('Remote module does not have a render function'))
        }

        unmount = module.unmount || (() => {})
      } catch (loadError) {
        console.error('Failed to load New Quizzes remote module:', loadError)
        captureException(loadError)
      }
    }

    handleLoadNewQuizzes()

    return () => {
      unmount()
    }
  }, [quizzesData])

  return <div id="root" ref={mountPoint} />
}
