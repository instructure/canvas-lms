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

import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {BorderWidth, BorderWidthValues} from '@instructure/emotion'
import {BaseBlock} from '../BaseBlock'
import {SeparatorLineBlockSettings} from './SeparatorLineBlockSettings'

const I18n = createI18nScope('block_content_editor')

export type SeparatorLineBlockProps = {
  thickness: BorderWidthValues
  settings: {
    separatorColor: string
    backgroundColor: string
  }
}

export const SeparatorLineBlockView = (props: SeparatorLineBlockProps) => {
  const borderWidth: BorderWidth = `0 0 ${props.thickness} 0`

  return (
    <View
      as="hr"
      data-testid="separator-line"
      borderWidth={borderWidth}
      borderColor="primary"
      margin="none"
      themeOverride={{
        borderColorPrimary: props.settings.separatorColor,
      }}
    />
  )
}

export const SeparatorLineBlock = (props: SeparatorLineBlockProps) => {
  return (
    <BaseBlock
      ViewComponent={SeparatorLineBlockView}
      EditViewComponent={SeparatorLineBlockView}
      EditComponent={SeparatorLineBlockView}
      componentProps={props}
      title={SeparatorLineBlock.craft.displayName}
      backgroundColor={props.settings.backgroundColor}
    />
  )
}

SeparatorLineBlock.craft = {
  displayName: I18n.t('Separator line') as string,
  related: {
    settings: SeparatorLineBlockSettings,
  },
}
