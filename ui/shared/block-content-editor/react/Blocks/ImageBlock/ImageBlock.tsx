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
import {BaseBlock} from '../BaseBlock'
import {useSave} from '../BaseBlock/useSave'
import {ImageBlockSettings} from './ImageBlockSettings'
import {ImageEdit, ImageView} from '../BlockItems/Image'
import {ImageBlockProps} from './types'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {TitleView} from '../BlockItems/Title/TitleView'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {Flex} from '@instructure/ui-flex'
import {useFocusElement} from '../../hooks/useFocusElement'
import {defaultProps} from './defaultProps'
import {getContrastingTextColorCached} from '../../utilities/getContrastingTextColor'

const I18n = createI18nScope('block_content_editor')

const ImageBlockView = (props: ImageBlockProps) => {
  return (
    <Flex direction="column" gap="mediumSmall">
      {props.includeBlockTitle && (
        <TitleView contentColor={props.titleColor || ''} title={props.title} />
      )}
      <ImageView {...props} />
    </Flex>
  )
}

const ImageBlockEditView = (props: ImageBlockProps) => {
  return (
    <Flex direction="column" gap="mediumSmall">
      {props.includeBlockTitle && (
        <TitleEditPreview contentColor={props.titleColor || ''} title={props.title} />
      )}
      <ImageView {...props} />
    </Flex>
  )
}

const ImageBlockEdit = (props: ImageBlockProps) => {
  const {focusHandler} = useFocusElement()
  const [title, setTitle] = useState(props.title || '')
  const labelColor = getContrastingTextColorCached(props.backgroundColor)

  const save = useSave(() => ({title}))

  return (
    <Flex direction="column" gap="mediumSmall">
      {props.includeBlockTitle && (
        <TitleEdit
          title={title}
          onTitleChange={setTitle}
          focusHandler={focusHandler}
          labelColor={labelColor}
        />
      )}
      <ImageEdit
        {...props}
        onImageChange={data => save({...data})}
        focusHandler={!props.includeBlockTitle && focusHandler}
      />
    </Flex>
  )
}

export const ImageBlock = (props: Partial<ImageBlockProps>) => {
  const componentProps = {...defaultProps, ...props}
  return (
    <BaseBlock
      ViewComponent={ImageBlockView}
      EditComponent={ImageBlockEdit}
      EditViewComponent={ImageBlockEditView}
      componentProps={componentProps}
      title={ImageBlock.craft.displayName}
      backgroundColor={componentProps.backgroundColor}
    />
  )
}

ImageBlock.craft = {
  displayName: I18n.t('Full width image') as string,
  related: {
    settings: ImageBlockSettings,
  },
}
