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
import {MediaBlock} from '../Blocks/MediaBlock'
import {SeparatorLineBlock} from '../Blocks/SeparatorLineBlock'
import {ButtonBlock} from '../Blocks/ButtonBlock'
import {HighlightBlock} from '../Blocks/HighlightBlock'
import {colors} from '@instructure/canvas-theme'
import {ImageTextBlock} from '../Blocks/ImageTextBlock'

const I18n = createI18nScope('block_content_editor')

type BlockFactory = {[key: string]: () => ReactElement}

const defaultBackgroundColor = colors.primitives.white
const defaultTextColor = colors.ui.textDescription

export const blockFactory = {
  [TextBlock.name]: () => (
    <TextBlock
      title=""
      content=""
      settings={{
        includeBlockTitle: true,
        backgroundColor: defaultBackgroundColor,
        titleColor: defaultTextColor,
      }}
    />
  ),
  [ImageBlock.name]: () => (
    <ImageBlock
      title=""
      url=""
      altText=""
      caption=""
      altTextAsCaption={false}
      decorativeImage={false}
      settings={{
        includeBlockTitle: true,
        backgroundColor: defaultBackgroundColor,
        textColor: defaultTextColor,
      }}
    />
  ),
  [SeparatorLineBlock.name]: () => (
    <SeparatorLineBlock
      thickness="medium"
      settings={{separatorColor: colors.ui.lineDivider, backgroundColor: defaultBackgroundColor}}
    />
  ),
  [ButtonBlock.name]: () => (
    <ButtonBlock
      settings={{
        includeBlockTitle: true,
        alignment: 'left',
        layout: 'horizontal',
        isFullWidth: false,
        buttons: [
          {
            id: 1,
            text: '',
            url: '',
            linkOpenMode: 'new-tab',
            primaryColor: colors.primitives.blue45,
            secondaryColor: colors.primitives.white,
            style: 'filled',
          },
        ],
        backgroundColor: defaultBackgroundColor,
        textColor: defaultTextColor,
      }}
      title=""
    />
  ),
  [HighlightBlock.name]: () => (
    <HighlightBlock
      content=""
      displayIcon="warning"
      highlightColor={colors.additionalPrimitives.ocean12}
      textColor={defaultTextColor}
      backgroundColor={defaultBackgroundColor}
    />
  ),
  [ImageTextBlock.name]: () => (
    <ImageTextBlock
      url=""
      altText=""
      fileName=""
      title=""
      content=""
      decorativeImage={false}
      includeBlockTitle={true}
      backgroundColor={defaultBackgroundColor}
      textColor={defaultTextColor}
      arrangement="left"
      textToImageRatio="1:1"
      altTextAsCaption={false}
      caption=""
    />
  ),
  [MediaBlock.name]: () => (
    <MediaBlock
      src=""
      title=""
      backgroundColor={defaultBackgroundColor}
      titleColor={defaultTextColor}
      includeBlockTitle={true}
    />
  ),
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
      {itemName: ImageTextBlock.craft.displayName, id: ImageTextBlock.name},
    ],
  },
  {
    groupName: I18n.t('Image'),
    items: [
      {itemName: ImageBlock.craft.displayName, id: ImageBlock.name},
      {itemName: ImageTextBlock.craft.displayName, id: ImageTextBlock.name},
    ],
  },
  {
    groupName: I18n.t('Highlight'),
    items: [{itemName: HighlightBlock.craft.displayName, id: HighlightBlock.name}],
  },
  {
    groupName: I18n.t('Multimedia'),
    items: [{itemName: MediaBlock.craft.displayName, id: MediaBlock.name}],
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
