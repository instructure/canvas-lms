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
import classNames from 'classnames'
import type {ViewOwnProps} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {useNavigate, useMatch} from 'react-router-dom'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

interface Props {
  className?: string
}

const SignInLinks = ({className}: Props) => {
  const navigate = useNavigate()
  const isSignIn = useMatch('/login/canvas')
  const isForgotPassword = useMatch('/login/canvas/forgot-password')

  const {isPreviewMode, isUiActionPending} = useNewLogin()

  const handleNavigate = (path: string) => (event: React.MouseEvent<ViewOwnProps>) => {
    event.preventDefault()

    if (!(isPreviewMode || isUiActionPending)) {
      navigate(path)
    }
  }

  return (
    <Flex className={classNames(className)} direction="column" gap="small">
      {isSignIn && (
        <Flex.Item overflowY="visible">
          <Link
            href="/login/canvas/forgot-password"
            onClick={handleNavigate('/login/canvas/forgot-password')}
          >
            {I18n.t('Forgot password?')}
          </Link>
        </Flex.Item>
      )}

      {isForgotPassword && (
        <Flex.Item overflowY="visible">
          <Link href="/login/canvas" onClick={handleNavigate('/login/canvas')}>
            {I18n.t('Sign in')}
          </Link>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default SignInLinks
