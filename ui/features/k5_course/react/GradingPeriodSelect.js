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
 */

import React, {useState, useEffect} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {GradingPeriodShape} from '@canvas/k5/react/utils'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'

const I18n = useI18nScope('course_grading_period_select')

const GradingPeriodSelect = ({
  loadingGradingPeriods,
  gradingPeriods,
  onGradingPeriodSelected,
  currentGradingPeriodId,
  courseName,
}) => {
  const ALL_PERIODS_VALUE = 'all'
  const [selectedValue, setSelectedValue] = useState(ALL_PERIODS_VALUE)

  useEffect(() => {
    onGradingPeriodSelected(selectedValue === ALL_PERIODS_VALUE ? null : selectedValue)
  }, [selectedValue, ALL_PERIODS_VALUE, onGradingPeriodSelected])

  useEffect(() => {
    setSelectedValue(currentGradingPeriodId || ALL_PERIODS_VALUE)
  }, [currentGradingPeriodId, ALL_PERIODS_VALUE])

  return (
    <LoadingWrapper
      id="grading-periods"
      isLoading={loadingGradingPeriods}
      display="block"
      height="2.2em"
      width="20rem"
      margin="medium 0"
      screenReaderLabel={I18n.t('Loading grading periods for %{courseName}', {courseName})}
    >
      {gradingPeriods && (
        <View as="div" margin="medium 0">
          <SimpleSelect
            data-testid="select-course-grading-period"
            renderLabel={
              <ScreenReaderContent>{I18n.t('Select Grading Period')}</ScreenReaderContent>
            }
            assistiveText={I18n.t('Use arrow keys to navigate options.')}
            isInline={true}
            onChange={(_e, data) => setSelectedValue(data.value)}
            width="20rem"
            value={selectedValue}
          >
            {gradingPeriods
              .filter(gp => gp.workflow_state === 'active')
              .map(gp => (
                <SimpleSelect.Option
                  id={`grading-period-${gp.id}`}
                  key={`grading-period-${gp.id}`}
                  value={gp.id}
                >
                  {gp.id === currentGradingPeriodId
                    ? I18n.t('%{title} (Current)', {title: gp.title})
                    : gp.title}
                </SimpleSelect.Option>
              ))}
            <SimpleSelect.Option
              id="grading-period-all"
              key="grading-period-all"
              value={ALL_PERIODS_VALUE}
            >
              {I18n.t('All Grading Periods')}
            </SimpleSelect.Option>
          </SimpleSelect>
        </View>
      )}
    </LoadingWrapper>
  )
}

GradingPeriodSelect.propTypes = {
  loadingGradingPeriods: PropTypes.bool.isRequired,
  gradingPeriods: PropTypes.arrayOf(PropTypes.shape(GradingPeriodShape)),
  onGradingPeriodSelected: PropTypes.func.isRequired,
  currentGradingPeriodId: PropTypes.string,
  courseName: PropTypes.string.isRequired,
}

export default GradingPeriodSelect
