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

import {useEditor} from '@craftjs/core'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SettingsTray} from './SettingsTray'
import {useBlockContentEditorContext} from '../BlockContentEditorContext'
import React from 'react'

const I18n = createI18nScope('block_content_editor')

export const SettingsTrayRenderer = () => {
  const {query} = useEditor()
  const {settingsTray} = useBlockContentEditorContext()

  let title = ''
  let settingComponent = null

  if (settingsTray.isOpen) {
    const node = query.node(settingsTray.blockId).get()
    title = I18n.t('%{blockDisplayName} block settings', {
      blockDisplayName: node.data.displayName,
    })
    settingComponent = React.createElement(node.related.settings)
  }

  return (
    <SettingsTray title={title} open={settingsTray.isOpen} onDismiss={settingsTray.close}>
      {settingComponent}
    </SettingsTray>
  )
}
