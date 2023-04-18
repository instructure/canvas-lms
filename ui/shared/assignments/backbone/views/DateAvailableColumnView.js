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
import template from '../../jst/DateAvailableColumnView.handlebars'
import $ from 'jquery'

extend(DateAvailableColumnView, Backbone.View)

function DateAvailableColumnView() {
  return DateAvailableColumnView.__super__.constructor.apply(this, arguments)
}

DateAvailableColumnView.prototype.template = template

DateAvailableColumnView.prototype.els = {
  '.vdd_tooltip_link': '$link',
}

DateAvailableColumnView.prototype.afterRender = function () {
  return this.$link.tooltip({
    position: {
      my: 'center bottom',
      at: 'center top-10',
      collision: 'fit fit',
    },
    tooltipClass: 'center bottom vertical',
    content() {
      return $($(this).data('tooltipSelector')).html()
    },
  })
}

DateAvailableColumnView.prototype.toJSON = function () {
  const group = this.model.defaultDates()
  const data = this.model.toView()
  data.defaultDates = group.toJSON()
  data.canManage = this.canManage()
  data.selector = this.model.get('id') + '_lock'
  data.linkHref = this.model.htmlUrl()
  data.allDates = this.model.allDates()
  return data
}

DateAvailableColumnView.prototype.canManage = function () {
  return ENV.PERMISSIONS.manage
}

export default DateAvailableColumnView
