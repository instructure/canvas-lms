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

import {TextBlockPreview} from './TextBlockPreview'
import {HighlightBlockPreview} from './HighlightBlockPreview'
import {ImageTextBlockPreview} from './ImageTextBlockPreview'
import {ImageBlockPreview} from './ImageBlockPreview'
import {VideoBlockPreview} from './VideoBlockPreview'
import {ButtonBlockPreview} from './ButtonBlockPreview'
import {SeparatorLineBlockPreview} from './SeparatorLineBlockPreview'
import {TextBlock} from '../Blocks/TextBlock'
import {ImageBlock} from '../Blocks/ImageBlock'
import {MediaBlock} from '../Blocks/MediaBlock'
import {SeparatorLineBlock} from '../Blocks/SeparatorLineBlock'
import {ButtonBlock} from '../Blocks/ButtonBlock'
import {HighlightBlock} from '../Blocks/HighlightBlock'
import {ImageTextBlock} from '../Blocks/ImageTextBlock'

export const previewFactory = {
  [TextBlock.name]: () => <TextBlockPreview />,
  [HighlightBlock.name]: () => <HighlightBlockPreview />,
  [ImageBlock.name]: () => <ImageBlockPreview />,
  [MediaBlock.name]: () => <VideoBlockPreview />,
  [ButtonBlock.name]: () => <ButtonBlockPreview />,
  [ImageTextBlock.name]: () => <ImageTextBlockPreview />,
  [SeparatorLineBlock.name]: () => <SeparatorLineBlockPreview />,
}
