/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import I18n from 'i18n!account_course_user_search'
import CoursesPane from '../components/CoursesPane'
import UsersPane from '../components/UsersPane'

export default [
  {
    pane: CoursesPane,
    path: '',
    title: I18n.t('Courses'),
    permissions: ['can_read_course_list'],
    button_class: 'courses'
  },
  {
    pane: UsersPane,
    path: '/users',
    title: I18n.t('People'),
    permissions: ['can_read_roster'],
    button_class: 'users'
  }
]
