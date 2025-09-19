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

import {ReactNode} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import './block-content-editor-layout.css'

const I18n = createI18nScope('block_content_editor')

export const BlockContentEditorLayout = (props: {
  toolbar: ReactNode
  editor: ReactNode
  mode: 'default' | 'preview'
}) => {
  const ariaLabel = props.mode === 'default' ? I18n.t('Content Area') : I18n.t('Preview')

  return (
    <section aria-label={I18n.t('Block Content Editor')} className="block-content-editor-container">
      <div role="toolbar" aria-label={I18n.t('Editor toolbar')} className="toolbar-area">
        {props.toolbar}
      </div>
      <div aria-label={ariaLabel} className="editor-area">
        {props.editor}
      </div>
    </section>
  )
}
