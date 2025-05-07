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

import React, {lazy} from 'react'
import {Route} from 'react-router-dom'
import {HelpTrayProvider, NewLoginDataProvider, NewLoginProvider} from '../context'
import {LoginLayout} from '../layouts/LoginLayout'
import {HelpTray} from '../shared'
import RegistrationRoutesMiddleware from './RegistrationRoutesMiddleware'
import RenderGuard from './RenderGuard'

const SignIn = lazy(() => import('../pages/SignIn'))
const ForgotPassword = lazy(() => import('../pages/ForgotPassword'))
const RegisterLanding = lazy(() => import('../pages/register/Landing'))
const RegisterStudent = lazy(() => import('../pages/register/Student'))
const RegisterParent = lazy(() => import('../pages/register/Parent'))
const RegisterTeacher = lazy(() => import('../pages/register/Teacher'))

export const NewLoginRoutes = (
  <Route
    path="login"
    element={
      <RenderGuard>
        <NewLoginProvider>
          <NewLoginDataProvider>
            <HelpTrayProvider>
              <LoginLayout />
              <HelpTray />
            </HelpTrayProvider>
          </NewLoginDataProvider>
        </NewLoginProvider>
      </RenderGuard>
    }
  >
    {/* standalone LDAP login route */}
    <Route path="ldap" element={<SignIn />} />
    {/* everything else under /login/canvas/… */}
    <Route path="canvas">
      <Route index={true} element={<SignIn />} />
      <Route path="forgot-password" element={<ForgotPassword />} />
      <Route path="register" element={<RegistrationRoutesMiddleware />}>
        <Route index={true} element={<RegisterLanding />} />
        <Route path="student" element={<RegisterStudent />} />
        <Route path="parent" element={<RegisterParent />} />
        <Route path="teacher" element={<RegisterTeacher />} />
      </Route>
      <Route path="*" element={<SignIn />} />
    </Route>
  </Route>
)
