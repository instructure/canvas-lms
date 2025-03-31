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
import {assignLocation} from '@canvas/util/globalUtils'
import {CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import type {ViewOwnProps} from '@instructure/ui-view'
import React from 'react'
import {useNavigate} from 'react-router-dom'
import {useNewLogin, useNewLoginData} from '../context'
import {ROUTES} from '../routes/routes'

const I18n = createI18nScope('new_login')

const ForgotPasswordLink = () => {
  const navigate = useNavigate()
  const {isUiActionPending} = useNewLogin()
  const {isPreviewMode, forgotPasswordUrl} = useNewLoginData()

  const isDisabled = isPreviewMode || isUiActionPending

  const handleNavigate =
    (path: string) =>
    (event: React.MouseEvent<ViewOwnProps> | React.KeyboardEvent<ViewOwnProps>) => {
      event.preventDefault()
      if (!isDisabled) {
        navigate(path)
      }
    }

  const handleForgotPasswordUrl =
    (url: string) =>
    (event: React.MouseEvent<ViewOwnProps> | React.KeyboardEvent<ViewOwnProps>) => {
      event.preventDefault()
      if (!isDisabled) {
        assignLocation(url)
      }
    }

  return (
    <Flex direction="column" gap="small">
      <Flex.Item overflowX="visible" overflowY="visible">
        {forgotPasswordUrl ? (
          <CondensedButton
            data-testid="forgot-password-link"
            href={forgotPasswordUrl}
            onClick={handleForgotPasswordUrl(forgotPasswordUrl)}
          >
            {I18n.t('Forgot password?')}
          </CondensedButton>
        ) : (
          <CondensedButton
            data-testid="forgot-password-link"
            href={ROUTES.FORGOT_PASSWORD}
            onClick={handleNavigate(ROUTES.FORGOT_PASSWORD)}
          >
            {I18n.t('Forgot password?')}
          </CondensedButton>
        )}
      </Flex.Item>
    </Flex>
  )
}

export default ForgotPasswordLink
