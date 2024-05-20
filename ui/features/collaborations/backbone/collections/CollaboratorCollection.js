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

import {extend as extend1} from '@canvas/backbone/utils'
import {extend, map} from 'lodash'
import {Collection, Model} from '@canvas/backbone'

extend1(CollaboratorCollection, Collection)

function CollaboratorCollection() {
  return CollaboratorCollection.__super__.constructor.apply(this, arguments)
}

CollaboratorCollection.prototype.model = Model

CollaboratorCollection.prototype.comparator = function (model) {
  return model.get('sortable_name') || model.get('name')
}

CollaboratorCollection.prototype.parse = function (response) {
  return map(response, function (model) {
    return extend(model, {
      id: model.type + '_' + model.collaborator_id,
    })
  })
}

export default CollaboratorCollection
