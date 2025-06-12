/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import ReactDOM from 'react-dom/client'
import React from 'react'
import {
  createBrowserRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from 'react-router-dom'
import {Spinner} from '@instructure/ui-spinner'
import accountGradingSettingsRoutes from '../../features/account_grading_settings/routes/accountGradingSettingsRoutes'
import {RubricRoutes} from '../../features/rubrics/routes/rubricRoutes'
import {NewLoginRoutes} from '../../features/new_login/routes/NewLoginRoutes'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AUPRoutes} from '../../features/acceptable_use_policy/routes/AUPRoutes'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {getTheme} from '@canvas/instui-bindings'
import {DynamicInstUISettingsProvider} from '@canvas/instui-bindings/react/DynamicInstUISettingProvider'

const portalRouter = createBrowserRouter(
  createRoutesFromElements(
    <Route>
      <Route path="/users/:userId/messages" lazy={() => import('../../features/messages/index')} />
      <Route
        path="/users/:userId/messages/:messageId"
        lazy={() => import('../../features/messages/index')}
      />
      <Route path="/login/otp" lazy={() => import('../../features/otp_login/index')} />
      <Route
        path="/groups/:groupId/*"
        lazy={() => import('@canvas/group-navigation-selector/GroupNavigationSelectorRoute')}
      />
      <Route
        path="/users/:userId/masquerade"
        lazy={() => import('../../features/act_as_modal/react/ActAsModalRoute')}
      />
      <Route
        path="/users/:userId/admin_merge"
        lazy={() => import('../../features/users_admin_merge/react/MergeUsersRoute')}
      />
      <Route
        path="/users/:userId"
        lazy={() => import('../../features/page_views/react/PageViewsRoute')}
      />
      <Route
        path="/courses/:courseId/wiki"
        lazy={() => import('../../features/wiki_page_show/index')}
      />
      <Route
        path="/courses/:courseId/pages/:pageId"
        lazy={() => import('../../features/wiki_page_show/index')}
      />
      <Route
        path="/groups/:groupId/wiki"
        lazy={() => import('../../features/wiki_page_show/index')}
      />
      <Route
        path="/groups/:groupId/pages/:pageId"
        lazy={() => import('../../features/wiki_page_show/index')}
      />
      <Route
        path="/accounts/:accountId/grading_standards"
        lazy={() => import('../../features/account_grading_standards/index')}
      />
      <Route
        path="/accounts/site_admin/release_notes"
        lazy={() => import('../../features/release_notes_edit/react/ReleaseNotesEditRoute')}
      />
      <Route
        path="/accounts/:accountId/admin_tools"
        lazy={() => import('../../features/account_admin_tools/react/AccountAdminToolsRoute')}
      />
      <Route
        path="/accounts/:accountId/settings/*"
        lazy={() => import('../../features/account_settings/react/AccountSettingsRoute')}
      />
      <Route
        path="/accounts/:accountId/users/:userId"
        lazy={() => import('../../features/page_views/react/PageViewsRoute')}
      />
      <Route
        path="/accounts/:accountId/authentication_providers"
        lazy={() =>
          import('../../features/authentication_providers/react/AuthenticationProviderRoute')
        }
      />
      <Route
        path="/accounts"
        lazy={() => import('../../features/account_manage/react/AccountListRoute')}
      />
      <Route
        path="/courses/:courseId/settings/*"
        lazy={() => import('../../features/course_settings/react/CourseSettingsRoute')}
      />
      <Route
        path="/courses/:courseId/search"
        lazy={() => import('../../features/search/react/SearchRoute')}
      />
      <Route
        path="/accounts/:accountId/sub_accounts"
        lazy={() => import('../../features/sub_accounts/react/SubaccountRoute')}
      />
      <Route
        path="/profile/qr_mobile_login"
        lazy={() => import('../../features/qr_mobile_login/react/QRMobileLoginRoute')}
      />
      <Route
        path="/search/all_courses"
        lazy={() => import('../../features/all_courses/react/AllCoursesRoute')}
      />

      {ENV.FEATURES.ams_service && (
        <Route
          path="/courses/:courseId/quizzes/*"
          lazy={() => import('../../features/ams/react/AmsRoute')}
        />
      )}

      {ENV.FEATURES.ams_service && (
        <Route
          path="/courses/:courseId/item_banks/*"
          lazy={() => import('../../features/ams/react/AmsRoute')}
        />
      )}

      {accountGradingSettingsRoutes}

      {(window.ENV.FEATURES.instui_nav || localStorage.instui_nav_dev) &&
        ['/', '/*', '/*/*'].map(path => (
          <Route
            key={`key-to-${path}`}
            path={path}
            lazy={() => import('../../features/navigation_header/react/NavigationHeaderRoute')}
          />
        ))}

      {window.ENV.FEATURES.login_registration_ui_identity && NewLoginRoutes}

      {AUPRoutes}

      {window.ENV.enhanced_rubrics_enabled && RubricRoutes}

      <Route
        path="/courses/:courseId/assignments/new"
        lazy={() => import('../../features/assignment_edit/index')}
      />
      <Route
        path="/courses/:courseId/assignments/:assignmentId/edit"
        lazy={() => import('../../features/assignment_edit/index')}
      />

      <Route path="*" element={<></>} />
    </Route>,
  ),
)

// ensure lazy evaluation at render time, preventing `I18n.t()` eager lookup violations
export function FallbackSpinner() {
  const I18n = createI18nScope('main')
  return <Spinner renderTitle={I18n.t('Loading page')} data-testid="fallback-spinner" />
}

export function loadReactRouter() {
  const mountNode = document.querySelector('#react-router-portals')
  if (mountNode) {
    const theme = getTheme()
    const root = ReactDOM.createRoot(mountNode)
    root.render(
      <DynamicInstUISettingsProvider theme={theme}>
        <QueryClientProvider client={queryClient}>
          <RouterProvider router={portalRouter} fallbackElement={<FallbackSpinner />} />
        </QueryClientProvider>
      </DynamicInstUISettingsProvider>,
    )
  }
}
