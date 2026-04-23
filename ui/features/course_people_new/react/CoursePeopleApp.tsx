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

import React, {FC} from 'react'
import {QueryClientProvider} from '@tanstack/react-query'
import CoursePeople from './CoursePeople'
import {ErrorBoundary} from '@instructure/platform-error-boundary'
import {GenericErrorPage} from '@instructure/platform-generic-error-page'
import {reportError, canvasErrorPageTranslations} from '@canvas/error-page-utils'
import errorShipUrl from '@instructure/platform-images/assets/ErrorShip.svg'
import CoursePeopleContext, {getCoursePeopleContext} from './contexts/CoursePeopleContext'
import {useScope as createI18nScope} from '@canvas/i18n'
import {queryClient} from '@instructure/platform-query'

const I18n = createI18nScope('course_people')

const CoursePeopleApp: FC = () => (
  <QueryClientProvider client={queryClient}>
    <CoursePeopleContext.Provider value={getCoursePeopleContext()}>
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorShipUrl}
            onReportError={reportError}
            translations={canvasErrorPageTranslations}
            errorCategory={I18n.t('Course People Error Page')}
          />
        }
      >
        <CoursePeople />
      </ErrorBoundary>
    </CoursePeopleContext.Provider>
  </QueryClientProvider>
)

export default CoursePeopleApp
