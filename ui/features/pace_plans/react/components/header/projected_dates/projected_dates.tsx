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

import React from 'react'
import {connect} from 'react-redux'
// @ts-ignore: TS doesn't understand i18n scoped imports
import I18n from 'i18n!pace_plans_projected_dates'

import {Flex} from '@instructure/ui-flex'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {StoreState} from '../../../types'
import {getPacePlanItems, getPlanWeeks} from '../../../reducers/pace_plans'
import {getShowProjections} from '../../../reducers/ui'
import PacePlanDateSelector from './date_selector'
import SlideTransition from '../../../utils/slide_transition'

interface StoreProps {
  readonly assignments: number
  readonly planWeeks: number
  readonly showProjections: boolean
}

type ComponentProps = StoreProps

export const ProjectedDates: React.FC<ComponentProps> = ({
  assignments,
  planWeeks,
  showProjections
}) => {
  return (
    <SlideTransition expanded={showProjections} direction="vertical" size="7rem">
      <View as="div">
        <Flex as="section" alignItems="start" margin="0 0 small">
          <PacePlanDateSelector type="start" />
          <View margin="0 0 0 medium">
            <PacePlanDateSelector type="end" />
          </View>
        </Flex>
        <Flex as="section" margin="0 0 small">
          <View padding="0 xxx-small 0 0" margin="0 x-small 0 0">
            <Text>
              <i>
                {I18n.t(
                  {
                    one: '1 assignment',
                    other: '%{count} assignments'
                  },
                  {count: assignments}
                )}
              </i>
            </Text>
          </View>
          <PresentationContent>
            <Text color="secondary">|</Text>
          </PresentationContent>
          <View margin="0 0 0 x-small">
            <Text>
              <i>
                {I18n.t(
                  {
                    one: '1 week',
                    other: '%{count} weeks'
                  },
                  {count: planWeeks}
                )}
              </i>
            </Text>
          </View>
        </Flex>
      </View>
    </SlideTransition>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    assignments: getPacePlanItems(state).length,
    planWeeks: getPlanWeeks(state),
    showProjections: getShowProjections(state)
  }
}

export default connect(mapStateToProps)(ProjectedDates)
