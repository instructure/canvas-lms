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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {NavLink, useMatch} from 'react-router-dom'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

const SignInLinks = () => {
  const isSignIn = useMatch('/login/canvas')
  const isForgotPassword = useMatch('/login/canvas/forgot-password')

  const getActiveClassName = ({isActive}: {isActive: boolean}) => (isActive ? 'active' : '')

  return (
    <Flex direction="column" gap="small">
      {isSignIn && (
        <Flex.Item>
          <NavLink to="/login/canvas/forgot-password" className={getActiveClassName}>
            {I18n.t('Forgot password?')}
          </NavLink>
        </Flex.Item>
      )}

      {isForgotPassword && (
        <Flex.Item>
          <NavLink to="/login/canvas" className={getActiveClassName}>
            {I18n.t('Sign in')}
          </NavLink>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default SignInLinks
