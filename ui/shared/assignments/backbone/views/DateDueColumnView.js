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
import template from '../../jst/DateDueColumnView.handlebars'
import $ from 'jquery'

extend(DateDueColumnView, Backbone.View)

function DateDueColumnView() {
  return DateDueColumnView.__super__.constructor.apply(this, arguments)
}

DateDueColumnView.prototype.template = template

DateDueColumnView.prototype.els = {
  '.vdd_tooltip_link': '$link',
}

DateDueColumnView.prototype.afterRender = function () {
  return this.$link.tooltip({
    position: {
      my: 'center bottom',
      at: 'center top-10',
      collision: 'fit fit',
    },
    tooltipClass: 'center bottom vertical',
    // eslint-disable-next-line object-shorthand
    content: function () {
      return $($(this).data('tooltipSelector')).html()
    },
  })
}

DateDueColumnView.prototype.toJSON = function () {
  const data = this.model.toView()
  const m = this.model.get('assignment') || this.model
  data.selector = m.get('id') + '_due'
  data.linkHref = m.htmlUrl()
  data.allDates = m.allDates()
  return data
}

export default DateDueColumnView
