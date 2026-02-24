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
import type {CamelizedGradingPeriod} from '@canvas/grading/grading.d'

import {useScope as createI18nScope} from '@canvas/i18n'
import ContentFilter from '@canvas/gradebook-content-filters/react/ContentFilter'

const I18n = createI18nScope(
  'gradebook_default_gradebook_components_content_filters_grading_period_filter',
)

function normalizeGradingPeriods(gradingPeriods: Array<{id: string; title: string}>) {
  return gradingPeriods.map(gradingPeriod => ({
    id: gradingPeriod.id,
    name:
      formatGradingPeriodTitleForDisplay(
        gradingPeriod as unknown as Pick<
          CamelizedGradingPeriod,
          'title' | 'startDate' | 'endDate' | 'closeDate'
        >,
      ) ?? gradingPeriod.title,
  }))
}

type Props = {
  disabled: boolean
  onSelect: (id: string) => void
  gradingPeriods: Array<{id: string; title: string}>
  selectedGradingPeriodId?: string | null
  [key: string]: unknown
}

export default function GradingPeriodFilter({
  disabled,
  onSelect,
  gradingPeriods,
  selectedGradingPeriodId,
  ...filterProps
}: Props) {
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
    }),
  ).isRequired,

  selectedGradingPeriodId: string,
}

GradingPeriodFilter.defaultProps = {
  selectedGradingPeriodId: null,
}
