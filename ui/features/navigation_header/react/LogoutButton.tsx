/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {Button, type ButtonProps} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import getCookie from '@instructure/get-cookie'

const I18n = useI18nScope('LogoutButton')

export default function LogoutButton(props: ButtonProps) {
  return (
    <form action="/logout" method="post">
      <input name="utf8" value="✓" type="hidden" />
      <input name="_method" value="delete" type="hidden" />
      <input name="authenticity_token" value={getCookie('_csrf_token')} type="hidden" />
      <Button type="submit" {...props}>
        {I18n.t('Logout')}
      </Button>
    </form>
  )
}
