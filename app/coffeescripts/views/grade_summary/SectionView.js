//
// Copyright (C) 2014 - present Instructure, Inc.
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

import {View} from 'Backbone'
import CollectionView from '../CollectionView'
import GroupView from './GroupView'
import template from 'jst/grade_summary/section'

export default class SectionView extends View {
  static initClass() {
    this.prototype.tagName = 'li'
    this.prototype.className = 'section'

    this.prototype.els = {'.groups': '$groups'}

    this.prototype.template = template
  }

  render() {
    super.render(...arguments)
    const groupsView = new CollectionView({
      el: this.$groups,
      collection: this.model.get('groups'),
      itemView: GroupView
    })
    return groupsView.render()
  }
}
SectionView.initClass()
