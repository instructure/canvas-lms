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

import Backbone from '@canvas/backbone'
import ProgressBarView from './ProgressBarView'
import template from '../../jst/alignment.handlebars'

export default class AlignmentView extends Backbone.View {
  static initClass() {
    this.prototype.tagName = 'li'
    this.prototype.className = 'alignment'
    this.prototype.template = template
  }

  initialize() {
    super.initialize(...arguments)
    return (this.progress = new ProgressBarView({model: this.model}))
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    return {...json, progress: this.progress}
  }
}
AlignmentView.initClass()
