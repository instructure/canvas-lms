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
import {render} from '@canvas/react'
import WidgetDashboardContainer from './react/WidgetDashboardContainer'
import ready from '@instructure/ready'
import {useScope as createI18nScope} from '@canvas/i18n'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {WidgetDashboardProvider} from './react/hooks/useWidgetDashboardContext'
import {WidgetDashboardEditProvider} from './react/hooks/useWidgetDashboardEdit'
import {WidgetLayoutProvider} from './react/hooks/useWidgetLayout'
import {Responsive} from '@instructure/ui-responsive'
import {ResponsiveProvider} from './react/hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

const RESPONSIVE_QUERY = {
  mobile: {maxWidth: '639px'},
  tablet: {minWidth: '640px', maxWidth: '1379px'},
  desktop: {minWidth: '1380px'},
}

ready(() => {
  const container = document.getElementById('content')

  if (container) {
    render(
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
            observedUserId={ENV.OBSERVED_USER_ID}
            currentUserRoles={ENV.current_user_roles}
            sharedCourseData={ENV.SHARED_COURSE_DATA}
            dashboardFeatures={ENV.DASHBOARD_FEATURES}
          >
            <WidgetDashboardEditProvider>
              <WidgetLayoutProvider>
                <Responsive
                  match="media"
                  query={RESPONSIVE_QUERY}
                  render={(_props, matches) => (
                    <ResponsiveProvider matches={matches || ['desktop']}>
                      <WidgetDashboardContainer />
                    </ResponsiveProvider>
                  )}
                />
              </WidgetLayoutProvider>
            </WidgetDashboardEditProvider>
          </WidgetDashboardProvider>
        </QueryClientProvider>
      </ErrorBoundary>,
      container,
    )
  }
})
