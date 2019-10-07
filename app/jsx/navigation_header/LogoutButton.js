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
import {Button} from '@instructure/ui-buttons'
import I18n from 'i18n!LogoutButton'

function readCookie(key) {
  return (document.cookie.match(`(^|; )${encodeURIComponent(key)}=([^;]*)`) || 0)[2]
}

export default function LogoutButton(props) {
  return (
    <form action="/logout" method="post">
      <input name="utf8" value="✓" type="hidden" />
      <input name="_method" value="delete" type="hidden" />
      <input name="authenticity_token" value={readCookie('_csrf_token')} type="hidden" />
      <Button type="submit" {...props}>
        {I18n.t('Logout')}
      </Button>
    </form>
  )
}

LogoutButton.propTypes = (() => {
  // we pass on all the same propTypes as instUI Button except for 'children'
  const {children, ...buttonpropTypes} = Button.propTypes
  return buttonpropTypes
})()
