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

import {View} from '@canvas/backbone'
import template from '../../jst/checkbox_view.handlebars'

class CheckboxView extends View {
  onClick(e) {
    e.preventDefault()
    return this.toggleState()
  }

  toggleState() {
    this.checked = !this.checked
    this.trigger('togglestate', this.checked)
    return this.render()
  }

  toJSON() {
    return {
      checked: this.checked.toString(),
      color: this.checked ? this.options.color : 'none',
      label: this.options.label,
    }
  }
}

CheckboxView.prototype.tagName = 'label'

CheckboxView.prototype.className = 'checkbox-view'

CheckboxView.optionProperty('color')

CheckboxView.optionProperty('label')

CheckboxView.prototype.checked = true

CheckboxView.prototype.template = template

CheckboxView.prototype.events = {
  click: 'onClick',
}

export default CheckboxView
