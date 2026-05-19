/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {useNewLogin, useNewLoginData} from '../context'
import React from 'react'
import {assignLocation} from '@canvas/util/globalUtils'
import {Link} from '@instructure/ui-link'
import {type ViewOwnProps} from '@instructure/ui-view'

const I18n = createI18nScope('new_login')

type Props = {
  url: string
}

const OtherWaysToLogin = ({url}: Props) => {
  const {isUiActionPending} = useNewLogin()
  const {discoveryEnabled, isPreviewMode} = useNewLoginData()

  if (!discoveryEnabled) return null

  const isDisabled = isPreviewMode || isUiActionPending

  const handleClick = (event: React.MouseEvent<ViewOwnProps>) => {
    event.preventDefault()
    if (!isDisabled) assignLocation(url)
  }

  return (
    <Link
      data-testid="other-ways-to-login-link"
      forceButtonRole={false}
      href={url}
      isWithinText={false}
      onClick={handleClick}
    >
      {I18n.t('Other ways to log in')}
    </Link>
  )
}

export default OtherWaysToLogin
