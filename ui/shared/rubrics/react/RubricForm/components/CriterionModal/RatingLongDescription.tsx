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
import {TextArea} from '@instructure/ui-text-area'
import {RubricRatingFieldSetting} from '../../types/RubricForm'

type RatingLongDescriptionProps = {
  limitHeight: boolean
  longDescription?: string
  setRatingForm: RubricRatingFieldSetting
  shouldRenderLabel: boolean
}

const I18n = createI18nScope('rubrics-criterion-modal')

export const RatingLongDescription = ({
  limitHeight,
  longDescription,
  setRatingForm,
  shouldRenderLabel,
}: RatingLongDescriptionProps) => {
  const labelText = I18n.t('Rating Description')
  const renderLabel = shouldRenderLabel ? (
    labelText
  ) : (
    <ScreenReaderContent>{labelText}</ScreenReaderContent>
  )

  return (
    <TextArea
      label={renderLabel}
      value={longDescription ?? ''}
      width="100%"
      height={limitHeight ? '2.25rem' : 'auto'}
      maxHeight={limitHeight ? '6.75rem' : 'auto'}
      onChange={e => setRatingForm('longDescription', e.target.value)}
      data-testid="rating-description"
    />
  )
}
