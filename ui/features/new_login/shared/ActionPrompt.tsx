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
import {Link} from '@instructure/ui-link'
import {ROUTES} from '../routes/routes'
import {Text} from '@instructure/ui-text'
import {useNavigate} from 'react-router-dom'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('new_login')

type Prompt = {
  text: string
  linkText: string
  linkHref: string
}

type ActionPromptProps = {
  variant: 'createAccount' | 'signIn' | 'createParentAccount'
}

const prompts: Record<ActionPromptProps['variant'], Prompt> = {
  createAccount: {
    text: I18n.t('Sign in or'),
    linkText: I18n.t('create an account.'),
    linkHref: ROUTES.REGISTER,
  },
  signIn: {
    text: I18n.t('Already have an account?'),
    linkText: I18n.t('Sign in'),
    linkHref: ROUTES.SIGN_IN,
  },
  createParentAccount: {
    text: I18n.t('Have a pairing code?'),
    linkText: I18n.t('Create a parent account'),
    linkHref: ROUTES.REGISTER_PARENT,
  },
}

const ActionPrompt = ({variant}: ActionPromptProps) => {
  const navigate = useNavigate()
  const {isPreviewMode, isUiActionPending} = useNewLogin()

  const {text, linkText, linkHref} = prompts[variant]
  const isDisabled = isPreviewMode || isUiActionPending

  const handleNavigate = (event: React.MouseEvent<ViewOwnProps>) => {
    event.preventDefault()
    if (!isDisabled) {
      navigate(linkHref)
    }
  }

  return (
    <Text>
      {text}{' '}
      <Link href={linkHref} onClick={handleNavigate}>
        {linkText}
      </Link>
    </Text>
  )
}

export default ActionPrompt
