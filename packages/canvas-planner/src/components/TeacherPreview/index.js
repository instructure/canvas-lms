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

import {string} from 'prop-types'
import formatMessage from '../../format-message'
import Day from '../Day'
import KinderPandaSvg from './kinder-panda.svg'

const noOp = () => {}

const COMMON_PROPS = {
  date: moment().hour(23).minute(59),
  dateStyle: 'due',
  points: 100,
  status: {}
}

const ITEMS = [
  {
    ...COMMON_PROPS,
    id: '1',
    uniqueId: 'assignment-1',
    context: {
      id: 'Math',
      type: 'Course',
      title: 'Math',
      color: '#BF32A4'
    },
    title: 'A wonderful assignment',
    type: 'Assignment'
  },
  {
    ...COMMON_PROPS,
    id: '2',
    uniqueId: 'assignment-2',
    context: {
      id: 'Math',
      type: 'Course',
      title: 'Math',
      color: '#BF32A4'
    },
    title: 'The best assignment',
    type: 'Assignment'
  },
  {
    ...COMMON_PROPS,
    id: '3',
    uniqueId: 'discussion-3',
    context: {
      id: 'Science',
      type: 'Course',
      title: 'Science',
      color: '#69B8DE'
    },
    title: 'A great discussion assignment',
    type: 'Discussion'
  },
  {
    ...COMMON_PROPS,
    id: '4',
    uniqueId: 'quiz-4',
    context: {
      id: 'Lang Arts',
      type: 'Course',
      title: 'Language Arts',
      color: '#E1AF52'
    },
    title: 'Fun quiz',
    type: 'Quiz'
  },
  {
    ...COMMON_PROPS,
    id: '5',
    uniqueId: 'discussion-5',
    context: {
      id: 'Soc Studies',
      type: 'Course',
      title: 'Social Studies',
      color: '#0081D3'
    },
    title: 'Exciting discussion',
    type: 'Discussion'
  }
]

export default function TeacherPreview({timeZone}) {
  return (
    <View as="section">
      <View as="section" margin="x-large large">
        <Flex direction="column" alignItems="center">
          <View as="section" margin="medium medium small medium">
            <KinderPandaSvg aria-hidden="true" data-testid="kinder-panda" />
          </View>
          <Text letterSpacing="expanded">
            <Heading as="h2" level="h3" margin="small">
              {formatMessage('Teacher Schedule Preview')}
            </Heading>
          </Text>
          <Text>
            {formatMessage('Below is an example of how your students will see their schedule')}
          </Text>
        </Flex>
      </View>
      <Day
        timeZone={timeZone}
        day={moment().format('YYYY-MM-DD')}
        itemsForDay={ITEMS}
        toggleCompletion={noOp}
        updateTodo={noOp}
        simplifiedControls
        showMissingAssignments={false}
      />
    </View>
  )
}

TeacherPreview.propTypes = {
  timeZone: string.isRequired
}
