/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {lazy, Suspense} from 'react'
import {Route} from 'react-router-dom'
import {LoginLayout} from '../layouts/LoginLayout'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

const SignIn = lazy(() => import('../pages/SignIn'))
const ForgotPassword = lazy(() => import('../pages/ForgotPassword'))

const Fallback = () => <Spinner renderTitle={I18n.t('Loading page')} />

export const NewLoginRoutes = (
  <Route path="/login/canvas" element={<LoginLayout />}>
    <Route
      index={true}
      element={
        <Suspense fallback={<Fallback />}>
          <SignIn />
        </Suspense>
      }
    />
    <Route
      path="forgot-password"
      element={
        <Suspense fallback={<Fallback />}>
          <ForgotPassword />
        </Suspense>
      }
    />
    <Route path="*" element={<SignIn />} />
  </Route>
)
