/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import React from 'react'
import CourseSelect, {ALL_COURSES_ID} from './CourseSelect'

export default {
  title: 'Examples/Canvas Inbox/Course Select',
  component: CourseSelect,
  argTypes: {
    onFailure: {action: 'failure_alert'},
    onSuccess: {action: 'success_alert'},
  },
}

const Template = args => (
  <AlertManagerContext.Provider
    value={{setOnFailure: args.onFailure, setOnSuccess: args.onSuccess}}
  >
    <CourseSelect {...args} />
  </AlertManagerContext.Provider>
)

const options = {
  allCourses: [
    {
      _id: ALL_COURSES_ID,
      contextName: 'All Courses',
      assetString: 'all_courses',
    },
  ],
  favoriteCourses: [
    {_id: 1, contextName: 'Charms', assetString: 'course_1'},
    {_id: 2, contextName: 'Transfiguration', assetString: 'course_2'},
  ],
  moreCourses: [
    {_id: 3, contextName: 'Potions', assetString: 'course_3'},
    {_id: 4, contextName: 'History of Magic', assetString: 'course_4'},
    {_id: 5, contextName: 'Herbology', assetString: 'course_5'},
    {_id: 6, contextName: 'Defense Against the Dark Arts', assetString: 'course_6'},
  ],
  concludedCourses: [
    {_id: 7, contextName: 'Muggle Studies', assetString: 'course_7'},
    {_id: 8, contextName: 'Astronomy', assetString: 'course_8'},
  ],
  groups: [
    {_id: 1, contextName: 'Gryffindor Bros', assetString: 'group_1'},
    {_id: 2, contextName: 'Quidditch', assetString: 'group_2'},
    {_id: 3, contextName: "Dumbledore's Army", assetString: 'group_3'},
  ],
}

export const MainPage = Template.bind({})
MainPage.args = {
  mainPage: true,
  options,
}

const composeModalOptions = JSON.parse(JSON.stringify(options))
delete composeModalOptions.concludedCourses
delete composeModalOptions.groups
export const ComposeModal = Template.bind({})
ComposeModal.args = {
  mainPage: false,
  options: composeModalOptions,
}
