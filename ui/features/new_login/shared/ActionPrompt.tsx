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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import type {ViewOwnProps} from '@instructure/ui-view'
import React from 'react'
import {useNavigate} from 'react-router-dom'
import {useNewLogin, useNewLoginData} from '../context'
import {ROUTES} from '../routes/routes'

const I18n = createI18nScope('new_login')

type ActionPromptProps = {
  variant: 'createAccount' | 'signIn' | 'createParentAccount'
}

const ActionPrompt = ({variant}: ActionPromptProps) => {
  const navigate = useNavigate()
  const {isUiActionPending} = useNewLogin()
  const {isPreviewMode} = useNewLoginData()

  const isDisabled = isPreviewMode || isUiActionPending

  const handleNavigate = (path: string) => (event: React.MouseEvent<ViewOwnProps>) => {
    event.preventDefault()
    if (!isDisabled) {
      navigate(path)
    }
  }

  switch (variant) {
    case 'createAccount':
      return (
        <Text>
          {I18n.t('Log in or')}{' '}
          <Link
            data-testid="create-account-link"
            href={ROUTES.REGISTER}
            onClick={handleNavigate(ROUTES.REGISTER)}
          >
            {I18n.t('create an account.')}
          </Link>
        </Text>
      )
    case 'signIn':
      return (
        <Text>
          {I18n.t('Already have an account?')}{' '}
          <Link
            data-testid="log-in-link"
            href={ROUTES.SIGN_IN}
            onClick={handleNavigate(ROUTES.SIGN_IN)}
          >
            {I18n.t('Log in')}
          </Link>
        </Text>
      )
    case 'createParentAccount':
      return (
        <Text>
          {I18n.t('Have a pairing code?')}{' '}
          <Link
            data-testid="create-parent-account-link"
            href={ROUTES.REGISTER_PARENT}
            onClick={handleNavigate(ROUTES.REGISTER_PARENT)}
          >
            {I18n.t('Create a Parent Account')}
          </Link>
        </Text>
      )
    default:
      return null
  }
}

export default ActionPrompt
