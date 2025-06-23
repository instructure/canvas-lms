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
import {SimpleSelect, SimpleSelectOption} from '@instructure/ui-simple-select'

const I18n = createI18nScope('rubrics-form')

type GradingTypeSelectProps = {
  freeFormCriterionComments: boolean
  onChange: (isFreeFormComments: boolean) => void
}

export const GradingTypeSelect = ({
  freeFormCriterionComments,
  onChange,
}: GradingTypeSelectProps) => {
  const handleChange = (value: string) => {
    onChange(value === 'freeForm')
  }

  const gradingType = freeFormCriterionComments ? 'freeForm' : 'scale'

  return (
    <SimpleSelect
      renderLabel={I18n.t('Type')}
      width={freeFormCriterionComments ? '12.563rem' : '10.563rem'}
      value={gradingType}
      onChange={(_e, {value}) => handleChange(value !== undefined ? value.toString() : '')}
      data-testid="rubric-rating-type-select"
    >
      <SimpleSelectOption id="scaleOption" value="scale" data-testid="rating_type_scale">
        {I18n.t('Scale')}
      </SimpleSelectOption>
      <SimpleSelectOption id="freeFormOption" value="freeForm" data-testid="rating_type_free_form">
        {I18n.t('Written Feedback')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}
