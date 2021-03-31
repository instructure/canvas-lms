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
import I18n from 'i18n!k5_dashboard'

import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {PresentationContent} from '@instructure/ui-a11y-content'

const GradingPeriodSelect = ({
  gradingPeriods,
  handleSelectGradingPeriod,
  selectedGradingPeriodId
}) => (
  <View as="div" margin="medium 0">
    <SimpleSelect
      id="grading-period-select"
      renderLabel={I18n.t('Select Grading Period')}
      assistiveText={I18n.t('Use arrow keys to navigate options.')}
      isInline
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
    </SimpleSelect>
    <PresentationContent>
      <hr />
    </PresentationContent>
  </View>
)

const GradingPeriodShape = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  end_date: PropTypes.string,
  start_date: PropTypes.string,
  workflow_state: PropTypes.string
}

GradingPeriodSelect.propTypes = {
  gradingPeriods: PropTypes.arrayOf(PropTypes.shape(GradingPeriodShape)).isRequired,
  handleSelectGradingPeriod: PropTypes.func.isRequired,
  selectedGradingPeriodId: PropTypes.string
}

export default GradingPeriodSelect
