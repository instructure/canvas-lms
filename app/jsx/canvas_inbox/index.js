/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {ApolloProvider, createClient} from 'jsx/canvas-apollo'
import ErrorBoundary from 'jsx/shared/components/ErrorBoundary'
import GenericErrorPage from 'jsx/shared/components/GenericErrorPage/index'
import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'
import AlertManager from 'jsx/shared/components/AlertManager'
import CanvasInbox from './containers/CanvasInbox'

const client = createClient()

export default function renderCanvasInboxApp(env, elt) {
  ReactDOM.render(
    <ApolloProvider client={client}>
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage imageUrl={errorShipUrl} errorCategory="Canvas Inbox Error Page" />
        }
      >
        <AlertManager>
          <CanvasInbox />
        </AlertManager>
      </ErrorBoundary>
    </ApolloProvider>,
    elt
  )
}
