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
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

interface Props {
  className?: string
}

const InstructureLogo = ({className}: Props) => {
  const {isPreviewMode, isUiActionPending} = useNewLogin()

  const handleClick = (event: React.MouseEvent<ViewOwnProps>) => {
    if (isPreviewMode || isUiActionPending) {
      event.preventDefault()
    }
  }

  return (
    <View as="div" className={classNames(className)} textAlign="center">
      <Link href="https://instructure.com" target="_blank" rel="external" onClick={handleClick}>
        <picture>
          <source
            media="(max-width: 48rem)"
            srcSet={require('../assets/images/instructure-logo-dark.svg')}
          />

          <Img
            width="7.9375rem"
            height="1.125rem"
            constrain="contain"
            src={require('../assets/images/instructure-logo.svg')}
            alt={I18n.t('Instructure Logo')}
          />
        </picture>
      </Link>
    </View>
  )
}

export default InstructureLogo
