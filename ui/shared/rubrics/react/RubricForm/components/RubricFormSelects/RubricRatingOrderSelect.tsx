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

type RubricRatingOrderSelectProps = {
  ratingOrder: string
  onChangeOrder: (ratingOrder: string) => void
}

export const RubricRatingOrderSelect = ({
  ratingOrder,
  onChangeOrder,
}: RubricRatingOrderSelectProps) => {
  const onChange = (value: string) => {
    onChangeOrder(value)
  }

  return (
    <SimpleSelect
      renderLabel={I18n.t('Rating Order')}
      width="10.563rem"
      value={ratingOrder}
      onChange={(_e, {value}) => onChange(value !== undefined ? value.toString() : '')}
      data-testid="rubric-rating-order-select"
    >
      <SimpleSelectOption
        id="highToLowOption"
        value="descending"
        data-testid="high_low_rating_order"
      >
        {I18n.t('High < Low')}
      </SimpleSelectOption>
      <SimpleSelectOption
        id="lowToHighOption"
        value="ascending"
        data-testid="low_high_rating_order"
      >
        {I18n.t('Low < High')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}
