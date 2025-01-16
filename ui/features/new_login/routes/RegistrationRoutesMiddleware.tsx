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

import React, {useMemo} from 'react'
import {Navigate, Outlet, useLocation} from 'react-router-dom'
import {useNewLoginData} from '../context'
import {SelfRegistrationType} from '../types'
import {ROUTES} from './routes'

interface Rules {
  [key: string]: (type: string) => boolean
}

const RegistrationRoutesMiddleware = () => {
  const {selfRegistrationType, isDataLoading} = useNewLoginData()
  const location = useLocation()

  const fallback = ROUTES.SIGN_IN

  // access rules based on selfRegistrationType
  const rules: Rules = useMemo(
    () => ({
      landing: type => type === SelfRegistrationType.ALL,
      student: type => type === SelfRegistrationType.ALL,
      parent: type => type === SelfRegistrationType.ALL || type === SelfRegistrationType.OBSERVER,
      teacher: type => type === SelfRegistrationType.ALL,
    }),
    [],
  )

  const computeRelativePath = (pathname: string): string =>
    pathname.replace(ROUTES.REGISTER, '').replace(/^\//, '') || 'landing'
  const relativePath = useMemo(() => computeRelativePath(location.pathname), [location.pathname])

  const rule = rules[relativePath]
  const registrationType = selfRegistrationType || ''
  const canAccess = rule ? rule(registrationType) : false

  // skip rendering during data loading (spinner managed in ContentLayout)
  if (isDataLoading) {
    return <></>
  }

  // redirect if the user does not have access
  if (!selfRegistrationType || !canAccess) {
    console.warn(
      `Unauthorized access attempt: selfRegistrationType=${selfRegistrationType}, route=${relativePath}`,
    )
    return <Navigate to={fallback} replace={true} state={{from: location.pathname}} />
  }

  return <Outlet />
}

export default RegistrationRoutesMiddleware
