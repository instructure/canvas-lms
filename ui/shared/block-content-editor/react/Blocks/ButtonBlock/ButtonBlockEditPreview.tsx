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

import {Flex} from '@instructure/ui-flex'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {ButtonBlockEditPreviewProps} from './types'
import {ButtonDisplay} from './ButtonDisplay'

export const ButtonBlockEditPreview = (props: ButtonBlockEditPreviewProps) => {
  return (
    <Flex direction="column" gap="mediumSmall">
      {props.settings.includeBlockTitle && <TitleEditPreview title={props.title} />}
      <ButtonDisplay dataTestId="button-block-edit-preview" settings={props.settings} />
    </Flex>
  )
}
