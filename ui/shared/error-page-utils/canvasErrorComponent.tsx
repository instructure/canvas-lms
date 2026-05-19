/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {GenericErrorPage} from '@instructure/platform-generic-error-page'
import errorShipUrl from '@instructure/platform-images/assets/ErrorShip.svg'
import type {ReactElement} from 'react'
import {canvasErrorPageTranslations, reportError} from './reportError'

type Options = {
  errorSubject?: string
  errorCategory?: string
  errorImageUrl?: string
}

/**
 * Returns the canvas-flavored GenericErrorPage element used by
 * `<CanvasModal>` from `@instructure/platform-instui-bindings` as its
 * `errorComponent` prop. Defaults to the ErrorShip image + canvas
 * translations and canvas's `reportError` handler.
 */
export function canvasErrorComponent(options: Options = {}): ReactElement {
  return (
    <GenericErrorPage
      imageUrl={options.errorImageUrl ?? errorShipUrl}
      onReportError={reportError}
      translations={canvasErrorPageTranslations}
      errorSubject={options.errorSubject}
      errorCategory={options.errorCategory}
    />
  )
}
