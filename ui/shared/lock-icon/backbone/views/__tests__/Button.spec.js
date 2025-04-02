/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import 'jquery-migrate'
import Button from '../Button'
import MasterCourseModuleLock from '../../../../context-modules/backbone/models/MasterCourseModuleLock'

describe('Button', () => {
  let buttons
  let model

  beforeEach(() => {
    buttons = []
    model = new MasterCourseModuleLock({
      is_master_course_master_content: true,
      is_master_course_child_content: false,
      restricted_by_master_course: true,
    })
    window.closeTooltipDebouncer = undefined
  })

  afterEach(() => {
    buttons.forEach((button) => button.$el.remove())
  })

  test('removes existing tooltips upon render', () => {
    const mountPoint = document.createElement('div')
    document.body.appendChild(mountPoint)
    const tooltip = document.createElement('div')
    tooltip.className = 'ui-tooltip'
    tooltip.innerHTML = 'tooltip contents'
    document.body.appendChild(tooltip)

    const viewOptions = {
      model,
      el: mountPoint,
      course_id: 1,
      content_type: 'assignment',
      content_id: 1,
    }

    const button = new Button(viewOptions)
    buttons << button

    button.render()

    expect(document.querySelectorAll('.ui-tooltip')).toHaveLength(0)
  })

  test('removes existing tooltips upon render of multiple buttons', () => {
    const tooltip = document.createElement('div')
    tooltip.className = 'ui-tooltip'
    tooltip.innerHTML = 'tooltip contents'
    document.body.appendChild(tooltip)

    for(var i = 0; i < 100; i++) {
      const mountPoint = document.createElement('div')
      document.body.appendChild(mountPoint)

      const viewOptions = {
        model,
        el: mountPoint,
        course_id: 1,
        content_type: 'assignment',
        content_id: 1,
      }

      const button = new Button(viewOptions)
      buttons << button
      button.render()
    }

    expect(document.querySelectorAll('.ui-tooltip')).toHaveLength(0)
  })
})
