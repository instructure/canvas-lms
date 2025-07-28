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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {RubricRatingFieldSetting} from '../../types/RubricForm'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('rubrics-criterion-modal')

type RatingDescriptionProps = {
  description?: string
  errorMessage: FormMessage[]
  setRatingForm: RubricRatingFieldSetting
  shouldRenderLabel: boolean
}
export const RatingDescription = ({
  description,
  errorMessage,
  setRatingForm,
  shouldRenderLabel,
}: RatingDescriptionProps) => {
  const labelText = I18n.t('Rating Name')
  const renderLabel = shouldRenderLabel ? (
    labelText
  ) : (
    <ScreenReaderContent>{labelText}</ScreenReaderContent>
  )

  return (
    <TextInput
      renderLabel={renderLabel}
      display="inline-block"
      value={description ?? ''}
      onChange={(_e, value) => setRatingForm('description', value)}
      data-testid="rating-name"
      messages={errorMessage}
      width="100%"
    />
  )
}
