// @ts-nocheck
/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React from 'react'
import {arrayOf, shape, string, bool, func} from 'prop-types'
import {formatGradingPeriodTitleForDisplay} from '../../Gradebook.utils'

import {useScope as useI18nScope} from '@canvas/i18n'
import ContentFilter from '@canvas/gradebook-content-filters/react/ContentFilter'

const I18n = useI18nScope(
  'gradebook_default_gradebook_components_content_filters_grading_period_filter'
)

function normalizeGradingPeriods(gradingPeriods) {
  return gradingPeriods.map(gradingPeriod => ({
    id: gradingPeriod.id,
    name: formatGradingPeriodTitleForDisplay(gradingPeriod),
  }))
}

export default function GradingPeriodFilter(props) {
  const {disabled, onSelect, gradingPeriods, selectedGradingPeriodId, ...filterProps} = props

  return (
    <ContentFilter
      {...filterProps}
      disabled={disabled}
      onSelect={onSelect}
      allItemsId="0"
      allItemsLabel={I18n.t('All Grading Periods')}
      items={normalizeGradingPeriods(gradingPeriods)}
      label={I18n.t('Grading Period Filter')}
      selectedItemId={selectedGradingPeriodId}
    />
  )
}

GradingPeriodFilter.propTypes = {
  disabled: bool.isRequired,
  onSelect: func.isRequired,
  gradingPeriods: arrayOf(
    shape({
      id: string.isRequired,
      title: string.isRequired,
    })
  ).isRequired,

  selectedGradingPeriodId: string,
}

GradingPeriodFilter.defaultProps = {
  selectedGradingPeriodId: null,
}
