//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from 'Backbone'

import _ from 'underscore'
import Role from '../models/Role'

export default class RolesCollection extends Backbone.Collection {
  // Method Summary
  //   Roles are ordered by base_role_type then alphabetically within those
  //   base role types. The order that these base role types live is defined
  //   by the sortOrder array. There is a special case however. AccountAdmin
  //   role always goes first. This uses the index of the sortOrder to ensure
  //   the correct order since comparator is just using _.sort in it's
  //   underlining implementation which is just ordering based on alphabetical
  //   correctness.
  // @api backbone override
  comparator(role) {
    const base_role_type = role.get('base_role_type')
    const index = _.indexOf(this.sortOrder, base_role_type)
    const role_name = role.get('role')

    let position_string = `${index}_${base_role_type}_${role_name}`

    if (base_role_type === role_name) {
      position_string = `${index}_${base_role_type}`
    }
    if (role_name === 'AccountAdmin') {
      position_string = `0_${base_role_type}`
    }

    return position_string
  }
}
RolesCollection.prototype.model = Role

RolesCollection.prototype.sortOrder = [
  'NoPermissions',
  'AccountMembership',
  'StudentEnrollment',
  'TaEnrollment',
  'TeacherEnrollment',
  'DesignerEnrollment',
  'ObserverEnrollment'
]
