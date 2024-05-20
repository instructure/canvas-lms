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
import moment from 'moment-timezone'

import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {string, bool} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import AnimatableDay from '../Day'
import KinderPanda from './KinderPanda'
import {MULTI_COURSE_ITEMS, SINGLE_COURSE_ITEMS} from './mock-items'

import {SMALL_MEDIA_QUERY, MEDIUM_MEDIA_QUERY} from '../responsiviser'

const smallMediaQuery = window.matchMedia(SMALL_MEDIA_QUERY)
const mediumMediaQuery = window.matchMedia(MEDIUM_MEDIA_QUERY)

const noOp = () => {}

const I18n = useI18nScope('planner')

export default function PlannerPreview({timeZone, singleCourse}) {
  let responsiveSize = 'large'
  if (smallMediaQuery.matches) responsiveSize = 'small'
  if (mediumMediaQuery.matches) responsiveSize = 'medium'

  return (
    <View as="section">
      <View as="section" margin="x-large large">
        <Flex direction="column" alignItems="center">
          <View as="section" margin="medium medium small medium">
            <KinderPanda aria-hidden="true" data-testid="kinder-panda" />
          </View>
          <Text letterSpacing="expanded">
            <Heading as="h2" level="h3" margin="small">
              {I18n.t('Schedule Preview')}
            </Heading>
          </Text>
          <Text>{I18n.t('Below is an example of how students will see their schedule')}</Text>
        </Flex>
      </View>
      <AnimatableDay
        timeZone={timeZone}
        day={moment().format('YYYY-MM-DD')}
        itemsForDay={singleCourse ? SINGLE_COURSE_ITEMS : MULTI_COURSE_ITEMS}
        toggleCompletion={noOp}
        updateTodo={noOp}
        simplifiedControls
        showMissingAssignments={false}
        responsiveSize={responsiveSize}
        singleCourseView={singleCourse}
      />
    </View>
  )
}

PlannerPreview.propTypes = {
  timeZone: string.isRequired,
  singleCourse: bool.isRequired,
}
