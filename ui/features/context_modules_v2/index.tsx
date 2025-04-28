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

import React from 'react'
import {createRoot} from 'react-dom/client'
import ModulesContainer from './react/ModulesContainer'
import ModulesStudentContainer from './react/ModulesStudentContainer'
import ready from '@instructure/ready'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {ContextModuleProvider} from './react/hooks/useModuleContext'

const I18n = createI18nScope('context_modules_v2')

const ENV = window.ENV as GlobalEnv

ready(() => {
  const container = document.getElementById('content')

  if (!ENV.course_id) {
    console.error(I18n.t('Course ID is required'))
    return
  }

  if (container) {
    const root = createRoot(container)
    root.render(
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorCategory={I18n.t('Context Modules Error Page')}
          />
        }
      >
        <QueryClientProvider client={queryClient}>
          <ContextModuleProvider
            courseId={ENV.course_id}
            isMasterCourse={ENV.MASTER_COURSE_SETTINGS?.IS_MASTER_COURSE ?? false}
            isChildCourse={ENV.MASTER_COURSE_SETTINGS?.IS_CHILD_COURSE ?? false}
            permissions={ENV.MODULES_PERMISSIONS}
            NEW_QUIZZES_BY_DEFAULT={ENV.NEW_QUIZZES_BY_DEFAULT}
            DEFAULT_POST_TO_SIS={ENV.DEFAULT_POST_TO_SIS}
          >
            {ENV.MODULES_PERMISSIONS?.readAsAdmin ? (
              <ModulesContainer />
            ) : (
              <ModulesStudentContainer />
            )}
          </ContextModuleProvider>
        </QueryClientProvider>
      </ErrorBoundary>,
    )
  }
})
