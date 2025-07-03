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

type ScoreTypeSelectProps = {
  hidePoints: boolean
  onChange: (shouldHidePoints: boolean) => void
}

export const ScoringTypeSelect = ({hidePoints, onChange}: ScoreTypeSelectProps) => {
  const handleChange = (value: string) => {
    onChange(value === 'unscored')
  }

  const scoreType = hidePoints ? 'unscored' : 'scored'

  return (
    <SimpleSelect
      renderLabel={I18n.t('Scoring')}
      width="10.563rem"
      value={scoreType}
      onChange={(_e, {value}) => handleChange(value !== undefined ? value.toString() : '')}
      data-testid="rubric-rating-scoring-type-select"
    >
      <SimpleSelectOption id="scoredOption" value="scored" data-testid="scoring_type_scored">
        {I18n.t('Scored')}
      </SimpleSelectOption>
      <SimpleSelectOption id="unscoredOption" value="unscored" data-testid="scoring_type_unscored">
        {I18n.t('Unscored')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}
