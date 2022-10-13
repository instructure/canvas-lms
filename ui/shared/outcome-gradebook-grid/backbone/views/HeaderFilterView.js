/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@canvas/backbone'
import 'jquery-kyle-menu'
import template from '../../jst/header_filter.handlebars'

const I18n = useI18nScope('gradebookHeaderFilterView')

class HeaderFilterView extends View {
  onClick(e) {
    e.preventDefault()
    e.stopPropagation()
    const key = e.target.getAttribute('data-method')
    this.closeMenu()
    this.updateLabel(key)
    return this.recalculateHeader(key)
  }

  closeMenu() {
    return this.$el.find('.al-trigger').data('kyleMenu').close()
  }

  updateLabel(key) {
    return this.$('.current-label').text(this.labels[key])
  }

  recalculateHeader(key) {
    if (key === 'average') {
      key = 'mean'
    }
    return this.redrawFn(this.grid, key)
  }
}

HeaderFilterView.prototype.className = 'text-right'

HeaderFilterView.prototype.template = template

HeaderFilterView.prototype.labels = {
  average: I18n.t('course_average', 'Course average'),
  median: I18n.t('course_median', 'Course median'),
}

HeaderFilterView.prototype.events = {
  'click li a': 'onClick',
}

HeaderFilterView.optionProperty('grid')

HeaderFilterView.optionProperty('redrawFn')

export default HeaderFilterView
