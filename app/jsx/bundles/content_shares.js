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
import ReactDOM from "react-dom"
import I18n from 'i18n!content_share'
import ReceivedContentView from "../content_shares/ReceivedContentView"
import ErrorBoundary from 'jsx/shared/components/ErrorBoundary'
import GenericErrorPage from 'jsx/shared/components/GenericErrorPage'
import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'

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
  container)
