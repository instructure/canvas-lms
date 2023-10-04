// @ts-nocheck
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {Story, Meta} from '@storybook/react'
import {CollapsableList, CollapsableListProps} from './CollapsableList'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {
  IconSettingsLine,
  IconAddressBookLine,
  IconModuleLine,
  IconHourGlassLine,
  IconAssignmentLine,
  IconQuizLine,
  IconDiscussionLine,
  IconDocumentLine,
  IconCalendarDayLine,
  // @ts-expect-error
} from '@instructure/ui-icons'

export default {
  title: 'Examples/ContentMigrations/CollapsableList',
  component: CollapsableList,
} as Meta

const Template: Story<CollapsableListProps> = args => {
  const {items} = args

  const [selectedIds, setSelectedIds] = useState<string[]>([])

  return (
    <>
      <View as="div" margin="small">
        <Text weight="bold">Selected IDs:&nbsp;</Text>
        <Text>{selectedIds.join(',')}</Text>
      </View>
      <View as="div" margin="small" padding="medium">
        <CollapsableList items={items} onChange={ids => setSelectedIds(ids)} />
      </View>
    </>
  )
}

export const Default = Template.bind({})
Default.args = {
  items: [
    {
      id: 'course-settings',
      label: 'Course Settings',
      icon: IconSettingsLine,
    },
    {
      id: 'syllabus-body',
      label: 'Syllabus Body',
      icon: IconAddressBookLine,
    },
    {
      id: 'course-pace',
      label: 'Course Pace',
      icon: IconHourGlassLine,
    },
    {
      id: 'modules',
      label: 'Modules',
      icon: IconModuleLine,
      children: [
        {
          id: 'module-1',
          label: 'Module 1',
        },
        {
          id: 'module-2',
          label: 'Module 2',
        },
        {
          id: 'module-3',
          label: 'Module 3',
        },
      ],
    },
    {
      id: 'assignments',
      label: 'Assignments',
      icon: IconAssignmentLine,
      children: [
        {
          id: 'assignment-1',
          label: 'Assignment 1',
        },
        {
          id: 'assignment-2',
          label: 'Assignment 2',
        },
        {
          id: 'assignment-3',
          label: 'Assignment 3',
        },
      ],
    },
    {
      id: 'quizzes',
      label: 'Quizzes',
      icon: IconQuizLine,
      children: [
        {
          id: 'quiz-1',
          label: 'Quiz 1',
        },
        {
          id: 'quiz-2',
          label: 'Quiz 2',
        },
        {
          id: 'quiz-3',
          label: 'Quiz 3',
        },
      ],
    },
    {
      id: 'discussion-topics',
      label: 'Discussion Topics',
      icon: IconDiscussionLine,
      children: [
        {
          id: 'discussion-1',
          label: 'Discussion 1',
        },
        {
          id: 'discussion-2',
          label: 'Discussion 2',
        },
        {
          id: 'discussion-3',
          label: 'Discussion 3',
        },
      ],
    },
    {
      id: 'pages',
      label: 'Pages',
      icon: IconDocumentLine,
      children: [
        {
          id: 'page-1',
          label: 'Page 1',
        },
        {
          id: 'page-2',
          label: 'Page 2',
        },
        {
          id: 'page-3',
          label: 'Page 3',
        },
      ],
    },
    {
      id: 'calendar-events',
      label: 'Calendar Events',
      icon: IconCalendarDayLine,
      children: [
        {
          id: 'event-1',
          label: 'Event 1',
        },
        {
          id: 'event-2',
          label: 'Event 2',
        },
        {
          id: 'event-3',
          label: 'Event 3',
        },
      ],
    },
  ],
}
