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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {HighlightBlockSettings} from './HighlightBlockSettings'
import {HighlightBlockLayout} from './HighlightBlockLayout'
import {getIcon} from './components/getIcon'
import {HighlightText} from './components/HighlightText'
import {HighlightTextEdit} from './components/HighlightTextEdit'
import {useSave} from '../BaseBlock/useSave'
import {BaseBlock} from '../BaseBlock'

const I18n = createI18nScope('block_content_editor')

const HighlightBlockView = (props: HighlightBlockProps) => {
  return (
    <HighlightBlockLayout
      icon={getIcon(props.displayIcon, props.textColor)}
      content={<HighlightText content={props.content} color={props.textColor} />}
      backgroundColor={props.highlightColor}
    />
  )
}

const HighlightBlockEditView = (props: HighlightBlockProps) => {
  const content = props.content || I18n.t('Click to edit')
  return <HighlightBlockView {...props} content={content} />
}

const HighlightBlockEdit = (props: HighlightBlockProps) => {
  const [content, setContent] = useState(props.content)

  useSave<typeof HighlightBlock>(() => ({
    content,
  }))

  return (
    <HighlightBlockLayout
      icon={getIcon(props.displayIcon, props.textColor)}
      content={<HighlightTextEdit content={content} setContent={setContent} />}
      backgroundColor={props.highlightColor}
    />
  )
}

export type HighlightBlockProps = {
  content: string
  displayIcon: string | null
  highlightColor: string
  textColor: string
  backgroundColor: string
}

export const HighlightBlock = (props: HighlightBlockProps) => {
  return (
    <BaseBlock
      ViewComponent={HighlightBlockView}
      EditViewComponent={HighlightBlockEditView}
      EditComponent={HighlightBlockEdit}
      componentProps={props}
      title={HighlightBlock.craft.displayName}
      backgroundColor={props.backgroundColor}
    />
  )
}

HighlightBlock.craft = {
  displayName: I18n.t('Highlight') as string,
  related: {
    settings: HighlightBlockSettings,
  },
}
