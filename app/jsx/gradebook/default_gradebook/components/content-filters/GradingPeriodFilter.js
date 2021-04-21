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
import {arrayOf, shape, string} from 'prop-types'

import I18n from 'i18n!gradebook_default_gradebook_components_content_filters_grading_period_filter'
import ContentFilter from './ContentFilter'

function normalizeGradingPeriods(gradingPeriods) {
  return gradingPeriods.map(gradingPeriod => ({
    id: gradingPeriod.id,
    name: gradingPeriod.title
  }))
}

export default function GradingPeriodFilter(props) {
  const {gradingPeriods, selectedGradingPeriodId, ...filterProps} = props

  return (
    <ContentFilter
      {...filterProps}
      allItemsId="0"
      allItemsLabel={I18n.t('All Grading Periods')}
      items={normalizeGradingPeriods(gradingPeriods)}
      label={I18n.t('Grading Period Filter')}
      selectedItemId={selectedGradingPeriodId}
    />
  )
}

GradingPeriodFilter.propTypes = {
  gradingPeriods: arrayOf(
    shape({
      id: string.isRequired,
      title: string.isRequired
    })
  ).isRequired,

  selectedGradingPeriodId: string
}

GradingPeriodFilter.defaultProps = {
  selectedGradingPeriodId: null
}
