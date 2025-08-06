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

import {BaseBlock, useGetRenderMode} from '../BaseBlock'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ButtonBlockEdit} from './ButtonBlockEdit'
import {ButtonBlockEditPreview} from './ButtonBlockEditPreview'
import {ButtonBlockView} from './ButtonBlockView'
import {ButtonBlockSettings} from './ButtonBlockSettings'

export type ButtonAlignment = 'left' | 'center' | 'right'

export type ButtonData = {
  id: number
}

export type ButtonBlockProps = {
  settings: {
    buttons: ButtonData[]
    alignment: ButtonAlignment
  }
}

export const ButtonBlockContent = (props: ButtonBlockProps) => {
  const {isEditMode, isEditPreviewMode} = useGetRenderMode()
  if (isEditMode) {
    return <ButtonBlockEdit settings={props.settings} />
  }

  if (isEditPreviewMode) {
    return <ButtonBlockEditPreview settings={props.settings} />
  }

  return <ButtonBlockView settings={props.settings} />
}

const I18n = createI18nScope('block_content_editor')

export const ButtonBlock = (props: ButtonBlockProps) => {
  return (
    <BaseBlock title={ButtonBlock.craft.displayName}>
      <ButtonBlockContent {...props} />
    </BaseBlock>
  )
}

ButtonBlock.craft = {
  displayName: I18n.t('Button') as string,
  related: {
    settings: ButtonBlockSettings,
  },
}
