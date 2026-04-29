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

import {ErrorBoundary} from '@instructure/platform-error-boundary'
import {GenericErrorPage} from '@instructure/platform-generic-error-page'
import {reportError, canvasErrorPageTranslations} from '@canvas/error-page-utils'
import errorShipUrl from '@instructure/platform-images/assets/ErrorShip.svg'
import React from 'react'

interface WizardErrorBoundaryProps {
  subject?: string
  category?: string
  imageUrl?: string
}

export const WizardErrorBoundary = ({
  children,
  subject,
  category,
  imageUrl = errorShipUrl,
}: React.PropsWithChildren<WizardErrorBoundaryProps>) => {
  return (
    <ErrorBoundary
      errorComponent={
        <GenericErrorPage
          imageUrl={imageUrl}
          onReportError={reportError}
          translations={canvasErrorPageTranslations}
          errorSubject={subject}
          errorCategory={category}
        />
      }
    >
      {children}
    </ErrorBoundary>
  )
}
