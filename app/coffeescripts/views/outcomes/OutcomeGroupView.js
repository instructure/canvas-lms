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

import _ from 'underscore'
import OutcomeContentBase from './OutcomeContentBase'
import outcomeGroupTemplate from 'jst/outcomes/outcomeGroup'
import outcomeGroupFormTemplate from 'jst/outcomes/outcomeGroupForm'

// For outcome groups
export default class OutcomeGroupView extends OutcomeContentBase {
  render() {
    const data = this.model.toJSON()
    switch (this.state) {
      case 'edit':
      case 'add':
        this.$el.html(outcomeGroupFormTemplate(data))
        this.readyForm()
        break
      case 'loading':
        this.$el.empty()
        break
      default:
        // show
        var canManage = !this.readOnly() && this.model.get('can_edit')
        this.$el.html(outcomeGroupTemplate(_.extend(data, {canManage})))
    }
    this.$('input:first').focus()
    return this
  }
}
