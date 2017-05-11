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
import CoursesPane from '../CoursesPane'
import UsersPane from '../UsersPane'

  const tabs = [
    {
      title: I18n.t('Courses'),
      pane: CoursesPane,
      path: '/courses',
      permissions: ['can_read_course_list']
    },
    {
      title: I18n.t('People'),
      pane: UsersPane,
      path: '/people',
      permissions: ['can_read_roster']
    }
  ];


export default tabs
