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
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {type ViewOwnProps} from '@instructure/ui-view'
import React from 'react'
import {useNewLogin, useNewLoginData} from '../context'

const I18n = createI18nScope('new_login')

const InstructureLogo = () => {
  const {isUiActionPending} = useNewLogin()
  const {isPreviewMode} = useNewLoginData()

  const isDisabled = isPreviewMode || isUiActionPending

  const handleClick = (event: React.MouseEvent<ViewOwnProps>) => {
    if (isDisabled) {
      event.preventDefault()
    }
  }

  return (
    <Link
      aria-disabled={isDisabled ? 'true' : 'false'}
      aria-label={I18n.t('By Instructure')}
      data-testid="instructure-logo-link"
      forceButtonRole={false}
      href="https://instructure.com"
      onClick={handleClick}
    >
      <Img
        // Img is decorative by default
        constrain="contain"
        data-testid="instructure-logo-img"
        height="1.125rem"
        src={require('../assets/images/instructure.svg')}
        width="7.9375rem"
        // InstUI v10 bug: <Img /> does not focus when display="block"
        // Semantically, this standalone image is block-level
      />
    </Link>
  )
}

export default InstructureLogo
