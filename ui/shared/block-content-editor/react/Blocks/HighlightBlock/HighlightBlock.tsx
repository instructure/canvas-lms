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

import {useEffect, useState, useCallback} from 'react'
import {BaseBlock, useGetRenderMode} from '../BaseBlock'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useSave} from '../BaseBlock/useSave'
import {HighlightBlockSettings} from './HighlightBlockSettings'
import {colors} from '@instructure/canvas-theme'
import {IconWarningLine} from '@instructure/ui-icons'
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import {HighlightBlockLayout} from './HighlightBlockLayout'

export type HighlightBlockProps = {
  content: string
}

export const HighlightBlockContent = (props: HighlightBlockProps) => {
  const {isEditMode, isEditPreviewMode} = useGetRenderMode()
  const save = useSave<typeof HighlightBlock>()

  const [content, setContent] = useState(props.content)

  const handleSave = useCallback(() => {
    save({content})
  }, [content, save])

  useEffect(() => {
    if (isEditPreviewMode) {
      handleSave()
    }
  }, [isEditPreviewMode, handleSave])

  const icon = (
    <IconWarningLine size="medium" style={{color: colors.additionalPrimitives.ocean30}} />
  )

  const contentSlot = isEditMode ? (
    <TextArea
      label={''}
      placeholder={I18n.t('Start typing...')}
      value={content}
      onChange={e => setContent(e.target.value)}
      resize="vertical"
    />
  ) : (
    <Text variant="contentImportant">{content || I18n.t('Click to edit')}</Text>
  )

  return (
    <HighlightBlockLayout
      icon={icon}
      content={contentSlot}
      backgroundColor={colors.additionalPrimitives.ocean12}
      textColor={colors.ui.textDescription}
    />
  )
}

const I18n = createI18nScope('block_content_editor')

export const HighlightBlock = (props: HighlightBlockProps) => {
  return (
    <BaseBlock title={HighlightBlock.craft.displayName}>
      <HighlightBlockContent {...props} />
    </BaseBlock>
  )
}

HighlightBlock.craft = {
  displayName: I18n.t('Highlight') as string,
  related: {
    settings: HighlightBlockSettings,
  },
}
