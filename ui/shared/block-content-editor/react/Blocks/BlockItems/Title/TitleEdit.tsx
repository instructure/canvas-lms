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

import {ChangeEvent} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TitleEditProps} from './types'

const I18n = createI18nScope('block_content_editor')

export const TitleEdit = ({title, onTitleChange, focusHandler, labelColor}: TitleEditProps) => {
  const handleOnChange = (event: ChangeEvent<HTMLInputElement>) => onTitleChange(event.target.value)
  const labelText = I18n.t('Block title')

  return (
    <TextInput
      elementRef={el => focusHandler?.(el as HTMLElement | null)}
      renderLabel={
        labelColor ? (
          <Text weight="weightImportant" color="primary" themeOverride={{primaryColor: labelColor}}>
            {labelText}
          </Text>
        ) : (
          <Tag size="medium" text={labelText} />
        )
      }
      placeholder={I18n.t('Start typing...')}
      value={title}
      onChange={handleOnChange}
    />
  )
}
