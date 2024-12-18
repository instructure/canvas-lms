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
import type {Story, Meta} from '@storybook/react'
import {CollapsableList, type CollapsableListProps} from './CollapsableList'
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
} from '@instructure/ui-icons'

export default {
  title: 'Examples/Content Migrations/CollapsableList',
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
      // @ts-expect-error
      icon: IconSettingsLine,
    },
    {
      id: 'syllabus-body',
      label: 'Syllabus Body',
      // @ts-expect-error
      icon: IconAddressBookLine,
    },
    {
      id: 'course-pace',
      label: 'Course Pace',
      // @ts-expect-error
      icon: IconHourGlassLine,
    },
    {
      id: 'modules',
      label: 'Modules',
      // @ts-expect-error
      icon: IconModuleLine,
      children: [
        {
          id: 'module-1',
          label: 'Module 1',
          // @ts-expect-error
          icon: IconModuleLine,
        },
        {
          id: 'module-2',
          label: 'Module 2',
          // @ts-expect-error
          icon: IconModuleLine,
        },
        {
          id: 'module-3',
          label: 'Module 3',
          // @ts-expect-error
          icon: IconModuleLine,
        },
        {
          id: 'module-4',
          label: 'Module 4',
          // @ts-expect-error
          icon: IconModuleLine,
          children: [
            {
              id: 'sub-module-1',
              label: 'Sub-Module 1',
            },
            {
              id: 'sub-module-2',
              label: 'Sub-Module 2',
            },
            {
              id: 'sub-module-3',
              label: 'Sub-Module 3',
            },
          ],
        },
        {
          id: 'module-5',
          label: 'Module 5',
          // @ts-expect-error
          icon: IconModuleLine,
          children: [
            {
              id: 'sub-module-4',
              label: 'Sub-Module 4',
            },
            {
              id: 'sub-module-5',
              label: 'Sub-Module 5',
            },
            {
              id: 'sub-module-6',
              label: 'Sub-Module 6',
            },
          ],
        },
      ],
    },
    {
      id: 'assignments',
      label: 'Assignments',
      // @ts-expect-error
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
      // @ts-expect-error
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
      // @ts-expect-error
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
      // @ts-expect-error
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
      // @ts-expect-error
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
