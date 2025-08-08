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

import {TextBlockEditProps} from './types'
import {Flex} from '@instructure/ui-flex'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {TextEdit} from '../BlockItems/Text/TextEdit'

export const TextBlockEdit = (props: TextBlockEditProps) => {
  return (
    <Flex direction="column" gap="mediumSmall">
      {props.settings.includeBlockTitle && (
        <TitleEdit title={props.title} onTitleChange={props.onTitleChange} />
      )}
      <TextEdit content={props.content} onContentChange={props.onContentChange} height={300} />
    </Flex>
  )
}
