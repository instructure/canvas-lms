/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import ReceivedContentView from './react/ReceivedContentView'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import ready from '@instructure/ready'

const I18n = useI18nScope('content_share')

ready(() => {
  const container = document.getElementById('content')
  ReactDOM.render(
    <ErrorBoundary
      errorComponent={
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorCategory={I18n.t('Content Shares Received View Error Page')}
        />
      }
    >
      <ReceivedContentView />
    </ErrorBoundary>,
    container
  )
})
