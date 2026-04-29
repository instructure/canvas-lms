/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Button} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ButtonViewProps} from './types'
import {getButtonText, getCommonButtonProps, getLinkProps} from './utils'
import './button.css'

const I18n = createI18nScope('block_content_editor')

export const ButtonView = (props: ButtonViewProps) => {
  const buttonText = getButtonText(props)
  const commonProps = getCommonButtonProps(props)
  const {href, target, rel, url, isNewTabLink} = getLinkProps(props)

  const buttonElement = (
    <Button {...commonProps} href={href} target={target} rel={rel}>
      {buttonText}
    </Button>
  )

  if (isNewTabLink && url) {
    return <Tooltip renderTip={I18n.t('Opens in new window')}>{buttonElement}</Tooltip>
  }

  return buttonElement
}
