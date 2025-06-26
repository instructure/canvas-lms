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
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import {assignLocation} from '@canvas/util/globalUtils'
import type {ViewOwnProps} from '@instructure/ui-view'
import {LOGIN_ENTRY_URL} from '../routes/routes'

const I18n = createI18nScope('new_login')

const SignInPrompt = () => {
  const handleClick = (event: React.MouseEvent<ViewOwnProps>) => {
    event.preventDefault()
    assignLocation(LOGIN_ENTRY_URL)
  }

  return (
    <Text>
      {I18n.t('Already have an account?')}{' '}
      <Link data-testid="log-in-link" href={LOGIN_ENTRY_URL} onClick={handleClick}>
        {I18n.t('Log in')}
      </Link>
    </Text>
  )
}

export default SignInPrompt
