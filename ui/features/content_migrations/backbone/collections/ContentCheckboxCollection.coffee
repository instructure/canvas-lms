#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from '@canvas/backbone'
import CheckboxModel from '../models/ContentCheckbox.coffee'

export default class ContentCheckboxCollection extends Backbone.Collection
  @optionProperty 'courseID'
  @optionProperty 'migrationID'
  @optionProperty 'isTopLevel'
  @optionProperty 'ariaLevel'

  # This is the default url. This can change for sub-level checkbox collections
  url: -> "/api/v1/courses/#{@courseID}/content_migrations/#{@migrationID}/selective_data"
  model: CheckboxModel
