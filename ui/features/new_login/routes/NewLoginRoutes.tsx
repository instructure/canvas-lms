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
import {Route, Outlet} from 'react-router-dom'
import {HelpTrayProvider, NewLoginDataProvider, NewLoginProvider} from '../context'
import RenderGuard from './RenderGuard'

import RegistrationRoutesMiddleware from './RegistrationRoutesMiddleware'

const SignIn = lazy(() => import('../pages/SignIn'))
const ForgotPassword = lazy(() => import('../pages/ForgotPassword'))
const RegisterLanding = lazy(() => import('../pages/register/Landing'))
const RegisterStudent = lazy(() => import('../pages/register/Student'))
const RegisterParent = lazy(() => import('../pages/register/Parent'))
const RegisterTeacher = lazy(() => import('../pages/register/Teacher'))
const LoginLayout = lazy(() => import('../layouts/LoginLayout'))
const HelpTray = lazy(() => import('../shared/HelpTray'))

function SuspenseWrapper() {
  return (
    <Suspense fallback={<div />}>
      <Outlet />
    </Suspense>
  )
}

export const NewLoginRoutes = (
  <Route element={<SuspenseWrapper />}>
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
      <Route element={<SuspenseWrapper />}>
        <Route path="ldap" element={<SignIn />} />
        <Route path="canvas" element={<SuspenseWrapper />}>
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
    </Route>
  </Route>
)
