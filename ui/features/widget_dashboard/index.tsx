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
import WidgetDashboardContainer from './react/WidgetDashboardContainer'
import ready from '@instructure/ready'
import {useScope as createI18nScope} from '@canvas/i18n'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {WidgetDashboardProvider} from './react/hooks/useWidgetDashboardContext'

const I18n = createI18nScope('widget_dashboard')

ready(() => {
  const container = document.getElementById('content')

  if (container) {
    const root = createRoot(container)
    root.render(
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorCategory={I18n.t('Widget Dashboard Error Page')}
          />
        }
      >
        <QueryClientProvider client={queryClient}>
          <WidgetDashboardProvider
            preferences={ENV.PREFERENCES}
            observedUsersList={ENV.OBSERVED_USERS_LIST}
            canAddObservee={ENV.CAN_ADD_OBSERVEE}
            currentUser={ENV.current_user}
            currentUserRoles={ENV.current_user_roles}
          >
            <WidgetDashboardContainer />
          </WidgetDashboardProvider>
        </QueryClientProvider>
      </ErrorBoundary>,
    )
  }
})
