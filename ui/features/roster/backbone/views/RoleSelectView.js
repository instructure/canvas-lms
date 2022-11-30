//
// Copyright (C) 2013 - present Instructure, Inc.
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

import SelectView from './SelectView'

import template from '../../jst/roleSelect.handlebars'

export default class RoleSelectView extends SelectView {
  static initClass() {
    this.optionProperty('rolesCollection')
    this.prototype.template = template
  }

  attach() {
    return this.rolesCollection.on('add reset remove change', this.render, this)
  }

  toJSON() {
    return {
      roles: this.rolesCollection.toJSON(),
      selectedRole: (this.el.selectedOptions != null ? this.el.selectedOptions.length : undefined)
        ? this.el.selectedOptions[0].value
        : '',
    }
  }
}
RoleSelectView.initClass()
