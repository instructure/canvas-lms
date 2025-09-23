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

import {PropsWithChildren} from 'react'
import CanvasTray from '@canvas/trays/react/Tray'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('block_content_editor')

export type SettingsTrayProps = PropsWithChildren<{
  blockDisplayName: string
  open: boolean
  onDismiss: () => void
  onClose: () => void
}>

export const SettingsTray = (props: SettingsTrayProps) => {
  return (
    <CanvasTray
      label={props.blockDisplayName}
      title={props.blockDisplayName}
      open={props.open}
      onDismiss={props.onDismiss}
      onClose={props.onClose}
      headerPadding="small small 0 small"
      contentPadding="small"
      placement="end"
      size="regular"
      data-testid="settings-tray"
      shouldCloseOnDocumentClick={true}
    >
      <Text variant="contentImportant">{I18n.t('Settings')}</Text>
      <View as="div" margin="medium 0 0 0">
        {props.children}
      </View>
    </CanvasTray>
  )
}
