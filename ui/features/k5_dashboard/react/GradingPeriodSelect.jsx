/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
 *
 */

import React from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'

import {GradingPeriodShape} from '@canvas/k5/react/utils'

const I18n = useI18nScope('dashboard_grading_period_select')

export const ALL_PERIODS_OPTION = 'all'

const GradingPeriodSelect = ({
  gradingPeriods,
  handleSelectGradingPeriod,
  selectedGradingPeriodId,
}) => (
  <View as="div">
    <SimpleSelect
      id="grading-period-select"
      renderLabel={I18n.t('Select Grading Period')}
      assistiveText={I18n.t('Use arrow keys to navigate options.')}
      isInline={true}
      onChange={handleSelectGradingPeriod}
      width="20rem"
      value={selectedGradingPeriodId}
    >
      <SimpleSelect.Option id="grading-period-default" value="">
        {I18n.t('Current Grading Period')}
      </SimpleSelect.Option>
      {gradingPeriods
        .filter(gp => gp.workflow_state === 'active')
        .map(({id, title}) => (
          <SimpleSelect.Option id={`grading-period-${id}`} key={`grading-period-${id}`} value={id}>
            {title}
          </SimpleSelect.Option>
        ))}
      <SimpleSelect.Option id="grading-period-all" value={ALL_PERIODS_OPTION}>
        {I18n.t('All Grading Periods')}
      </SimpleSelect.Option>
    </SimpleSelect>
  </View>
)

GradingPeriodSelect.propTypes = {
  gradingPeriods: PropTypes.arrayOf(PropTypes.shape(GradingPeriodShape)).isRequired,
  handleSelectGradingPeriod: PropTypes.func.isRequired,
  selectedGradingPeriodId: PropTypes.string,
}

export default GradingPeriodSelect
