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

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'

extend(SpeedgraderLinkView, Backbone.View)

function SpeedgraderLinkView() {
  this.toggleSpeedgraderLink = this.toggleSpeedgraderLink.bind(this)
  return SpeedgraderLinkView.__super__.constructor.apply(this, arguments)
}

SpeedgraderLinkView.prototype.initialize = function () {
  SpeedgraderLinkView.__super__.initialize.apply(this, arguments)
  return this.model.on('change:published', this.toggleSpeedgraderLink)
}

SpeedgraderLinkView.prototype.toggleSpeedgraderLink = function () {
  if (this.model.get('published')) {
    return this.$el.removeClass('hidden')
  } else {
    return this.$el.addClass('hidden')
  }
}

export default SpeedgraderLinkView
