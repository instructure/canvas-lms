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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import ModuleItemCollection from '../collections/ModuleItemCollection'

extend(Module, Backbone.Model)

function Module() {
  return Module.__super__.constructor.apply(this, arguments)
}

Module.prototype.resourceName = 'modules'

Module.prototype.initialize = function () {
  let items, ref
  this.course_id = this.get('course_id')
  if (this.collection) {
    this.course_id || (this.course_id = this.collection.course_id)
  }
  if (!((ref = this.collection) != null ? ref.skip_items : void 0)) {
    items = this.get('items')
    this.itemCollection = new ModuleItemCollection(items, {
      module_id: this.get('id'),
      course_id: this.course_id,
    })
    if (!items) {
      this.itemCollection.setParam('per_page', 50)
      this.itemCollection.fetch()
    }
  }
  return Module.__super__.initialize.apply(this, arguments)
}

export default Module
