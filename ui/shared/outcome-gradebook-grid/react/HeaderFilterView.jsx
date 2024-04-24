/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {func, string, object} from 'prop-types'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

const HeaderFilterView = ({ grid, averageFn, redrawFn }) => {
  const calculationMethods = {
    mean: I18n.t('course_average', 'Course average'),
    median: I18n.t('course_median', 'Course median'),
  }

  const getCalculationMethod = (method) => {
    return calculationMethods[method]
  }

  const onOptionClick = (calcMethod) => {
    // Do not recalculate if calcMethod is the current calculation method
    if (calcMethod === averageFn) {
      return
    }

    redrawFn(grid, calcMethod)
  }

  return (
    <View>
      <Flex justifyItems="end">
        <Flex.Item>
          <Text weight="bold" size="small">
            {getCalculationMethod(averageFn)}
          </Text>
        </Flex.Item>
        <Flex.Item padding="0 x-small 0 0">
          <Menu
            withArrow={true}
            shouldHideOnSelect={true}
            trigger={
              <IconButton
                data-testid="lmgb-course-calc-dropdown"
                renderIcon={IconMiniArrowDownSolid}
                withBackground={false}
                withBorder={false}
                size="small"
                screenReaderLabel={I18n.t('Display Course Calculation Options')}
              />
            }
          >
            <Menu.Group
              data-testid="course-calc-group"
              label={I18n.t('Calculations')}
            >
              <Menu.Item
                data-testid="course-average-calc-option"
                selected={averageFn === "mean"}
                onSelect={() => onOptionClick("mean")}
              >
                {getCalculationMethod("mean")}
              </Menu.Item>
              <Menu.Item
                data-testid="course-median-calc-option"
                selected={averageFn === "median"}
                onSelect={() => onOptionClick("median")}
              >
                {getCalculationMethod("median")}
              </Menu.Item>
            </Menu.Group>
          </Menu>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default HeaderFilterView
