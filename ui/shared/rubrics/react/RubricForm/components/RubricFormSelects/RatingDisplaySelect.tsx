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

type RatingDisplaySelectProps = {
  buttonDisplay: string
  onChange: (buttonDisplay: string) => void
}

export const RatingDisplaySelect = ({buttonDisplay, onChange}: RatingDisplaySelectProps) => {
  const handleChange = (value: string) => {
    onChange(value)
  }

  return (
    <SimpleSelect
      renderLabel={I18n.t('Rating Display')}
      width="10.563rem"
      value={buttonDisplay}
      onChange={(_e, {value}) => handleChange(value !== undefined ? value.toString() : '')}
      data-testid="rubric-rating-display-select"
    >
      <SimpleSelectOption id="numericOption" value="numeric" data-testid="rating_type_numeric">
        {I18n.t('Level')}
      </SimpleSelectOption>
      <SimpleSelectOption id="pointsOption" value="points" data-testid="rating_type_points">
        {I18n.t('Points')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}
