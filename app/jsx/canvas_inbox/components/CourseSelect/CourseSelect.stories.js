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

import React from 'react'
import {CourseSelect} from './CourseSelect'

export default {
  title: 'Examples/Canvas Inbox/Course Select',
  component: CourseSelect
}

const Template = args => <CourseSelect {...args} />

const options = {
  favoriteCourses: [
    {id: 1, contextName: 'Charms', contextId: 'course_1'},
    {id: 2, contextName: 'Transfiguration', contextId: 'course_2'}
  ],
  moreCourses: [
    {id: 3, contextName: 'Potions', contextId: 'course_3'},
    {id: 4, contextName: 'History of Magic', contextId: 'course_4'},
    {id: 5, contextName: 'Herbology', contextId: 'course_5'},
    {id: 6, contextName: 'Defense Against the Dark Arts', contextId: 'course_6'}
  ],
  concludedCourses: [
    {id: 7, contextName: 'Muggle Studies', contextId: 'course_7'},
    {id: 8, contextName: 'Astronomy', contextId: 'course_8'}
  ],
  groups: [
    {id: 1, contextName: 'Gryffindor Bros', contextId: 'group_1'},
    {id: 2, contextName: 'Quidditch', contextId: 'group_2'},
    {id: 3, contextName: "Dumbledore's Army", contextId: 'group_3'}
  ]
}

export const MainPage = Template.bind({})
MainPage.args = {
  mainPage: true,
  options
}

const composeModalOptions = JSON.parse(JSON.stringify(options))
delete composeModalOptions.concludedCourses
delete composeModalOptions.groups
export const ComposeModal = Template.bind({})
ComposeModal.args = {
  mainPage: false,
  options: composeModalOptions
}
