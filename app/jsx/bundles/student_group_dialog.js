/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import ready from '@instructure/ready'
import Group from 'compiled/models/Group'
import GroupCategory from 'compiled/models/GroupCategory'
import GroupEditView from 'compiled/views/groups/manage/GroupEditView'

ready(() => {
  const group = new Group(ENV.group)
  const groupCategory = new GroupCategory(ENV.group_category)
  const editView = new GroupEditView({model: group, groupCategory, nameOnly: true})
  editView.setTrigger($('#edit_group'))
})
