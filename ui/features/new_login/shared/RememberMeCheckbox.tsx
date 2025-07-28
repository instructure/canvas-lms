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
import {Checkbox} from '@instructure/ui-checkbox'
import React from 'react'
import {useNewLogin} from '../context'

const I18n = createI18nScope('new_login')

const RememberMeCheckbox = () => {
  const {rememberMe, setRememberMe, isUiActionPending} = useNewLogin()

  return (
    <Checkbox
      label={I18n.t('Remember me')}
      checked={rememberMe}
      onChange={() => setRememberMe(!rememberMe)}
      inline={true}
      disabled={isUiActionPending}
      data-testid="remember-me-checkbox"
    />
  )
}

export default RememberMeCheckbox
