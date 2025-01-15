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
import type {ViewOwnProps} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {ROUTES} from '../routes/routes'
import {useMatch, useNavigate} from 'react-router-dom'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('new_login')

const SignInLinks = () => {
  const navigate = useNavigate()
  const {isPreviewMode, isUiActionPending, forgotPasswordUrl} = useNewLogin()
  const isSignIn = useMatch(ROUTES.SIGN_IN)
  const isForgotPassword = useMatch(ROUTES.FORGOT_PASSWORD)

  const isDisabled = isPreviewMode || isUiActionPending

  const handleNavigate = (path: string) => (event: React.MouseEvent<ViewOwnProps>) => {
    event.preventDefault()
    if (!isDisabled) {
      navigate(path)
    }
  }

  const handleForgotPasswordUrl = (url: string) => (event: React.MouseEvent<ViewOwnProps>) => {
    event.preventDefault()
    if (!isDisabled) {
      window.location.href = url
    }
  }

  return (
    <Flex direction="column" gap="small">
      {isSignIn && (
        <Flex.Item overflowX="visible" overflowY="visible">
          {forgotPasswordUrl ? (
            <Link href={forgotPasswordUrl} onClick={handleForgotPasswordUrl(forgotPasswordUrl)}>
              {I18n.t('Forgot password?')}
            </Link>
          ) : (
            <Link onClick={handleNavigate(ROUTES.FORGOT_PASSWORD)}>
              {I18n.t('Forgot password?')}
            </Link>
          )}
        </Flex.Item>
      )}

      {isForgotPassword && (
        <Flex.Item overflowX="visible" overflowY="visible">
          <Link onClick={handleNavigate(ROUTES.SIGN_IN)}>{I18n.t('Sign in')}</Link>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default SignInLinks
