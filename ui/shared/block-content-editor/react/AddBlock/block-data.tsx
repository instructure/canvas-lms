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
import {TextBlock} from '../Blocks/TextBlock'
import {ReactElement} from 'react'
import {ImageBlock} from '../Blocks/ImageBlock'
import {SeparatorLineBlock} from '../Blocks/SeparatorLineBlock'
import {ButtonBlock} from '../Blocks/ButtonBlock'
import {HighlightBlock} from '../Blocks/HighlightBlock'

const I18n = createI18nScope('block_content_editor')

type BlockFactory = {[key: string]: () => ReactElement}

export const blockFactory = {
  [TextBlock.name]: () => <TextBlock title="" content="" settings={{includeBlockTitle: true}} />,
  [ImageBlock.name]: () => <ImageBlock url="" altText="" />,
  [SeparatorLineBlock.name]: () => <SeparatorLineBlock thickness="small" />,
  [ButtonBlock.name]: () => <ButtonBlock settings={{buttons: [{id: 1}]}} />,
  [HighlightBlock.name]: () => <HighlightBlock content="" />,
  imageText: () => <p>image_text</p>,
  video: () => <p>video</p>,
} as const satisfies BlockFactory

export type BlockTypes = keyof typeof blockFactory

export type BlockData = {
  groupName: string
  items: {
    itemName: string
    id: BlockTypes
  }[]
}

export const blockData: BlockData[] = [
  {
    groupName: I18n.t('Text'),
    items: [
      {itemName: TextBlock.craft.displayName, id: TextBlock.name},
      {itemName: HighlightBlock.craft.displayName, id: HighlightBlock.name},
      {itemName: I18n.t('Image + text'), id: 'imageText'},
    ],
  },
  {
    groupName: I18n.t('Image'),
    items: [
      {itemName: ImageBlock.craft.displayName, id: ImageBlock.name},
      {itemName: I18n.t('Image + text'), id: 'imageText'},
    ],
  },
  {
    groupName: I18n.t('Highlight'),
    items: [{itemName: HighlightBlock.craft.displayName, id: HighlightBlock.name}],
  },
  {
    groupName: I18n.t('Multimedia'),
    items: [{itemName: I18n.t('Video'), id: 'video'}],
  },
  {
    groupName: I18n.t('Interactive element'),
    items: [{itemName: ButtonBlock.craft.displayName, id: ButtonBlock.name}],
  },
  {
    groupName: I18n.t('Divider'),
    items: [{itemName: SeparatorLineBlock.craft.displayName, id: SeparatorLineBlock.name}],
  },
]
