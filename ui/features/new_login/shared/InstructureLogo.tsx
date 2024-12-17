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
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {type ViewOwnProps} from '@instructure/ui-view'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('new_login')

const InstructureLogo = () => {
  const {isPreviewMode, isUiActionPending} = useNewLogin()

  const isDisabled = isPreviewMode || isUiActionPending

  const handleClick = (event: React.MouseEvent<ViewOwnProps>) => {
    if (isDisabled) {
      event.preventDefault()
    }
  }

  return (
    <Link
      aria-label={I18n.t('By Instructure')}
      href="https://instructure.com"
      onClick={handleClick}
      target="_blank"
    >
      <Img
        constrain="contain"
        display="block"
        height="1.125rem"
        src={require('../assets/images/instructure.svg')}
        width="7.9375rem"
      />
    </Link>
  )
}

export default InstructureLogo
