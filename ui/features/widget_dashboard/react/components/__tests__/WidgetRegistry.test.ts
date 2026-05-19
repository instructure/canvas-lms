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

import widgetRegistry, {
  getWidget,
  getAllWidgets,
  getWidgetsForRole,
  isRegisteredWidget,
  registerWidget,
} from '../WidgetRegistry'
import {WIDGET_TYPES, EDUCATOR_WIDGET_ROLE} from '../../constants'
import type {WidgetRegistry as WidgetRegistryType, WidgetRenderer} from '../../types'

describe('WidgetRegistry', () => {
  let snapshot: WidgetRegistryType

  beforeEach(() => {
    snapshot = {...widgetRegistry}
  })

  // registerWidget() mutates the module-level singleton, so restore after each test
  afterEach(() => {
    Object.keys(widgetRegistry).forEach(key => delete widgetRegistry[key])
    Object.assign(widgetRegistry, snapshot)
  })

  it('returns CourseWorkCombinedWidget for course_work_combined type', () => {
    const widget = getWidget(WIDGET_TYPES.COURSE_WORK_COMBINED)

    expect(widget).toBeDefined()
    expect(widget?.displayName).toBe('Course work')
    expect(widget?.description).toBe(
      'View course work statistics and assignments in one comprehensive view',
    )
    expect(widget?.component).toBeDefined()
  })

  it('returns undefined for unknown widget type', () => {
    const widget = getWidget('unknown_type')

    expect(widget).toBeUndefined()
  })

  it('correctly identifies registered widgets', () => {
    expect(isRegisteredWidget(WIDGET_TYPES.COURSE_WORK_COMBINED)).toBe(true)
    expect(isRegisteredWidget('unknown_type')).toBe(false)
  })

  it('returns all registered widgets', () => {
    const allWidgets = getAllWidgets()

    expect(allWidgets).toHaveProperty(WIDGET_TYPES.COURSE_WORK_COMBINED)
    expect(Object.keys(allWidgets)).toContain(WIDGET_TYPES.COURSE_WORK_COMBINED)
  })

  it('allows registering new widgets', () => {
    const mockRenderer: WidgetRenderer = {
      component: () => null,
      displayName: 'Test Widget',
      description: 'A test widget',
    }

    registerWidget('test_widget', mockRenderer)

    expect(isRegisteredWidget('test_widget')).toBe(true)
    expect(getWidget('test_widget')).toBe(mockRenderer)
  })

  describe('getWidgetsForRole', () => {
    beforeEach(() => {
      Object.keys(widgetRegistry).forEach(key => delete widgetRegistry[key])
      registerWidget('educator_widget', {
        component: () => null,
        displayName: 'Educator Widget',
        description: 'An educator-only widget',
        roles: [EDUCATOR_WIDGET_ROLE],
      })
      registerWidget('learner_widget', {
        component: () => null,
        displayName: 'Learner Widget',
        description: 'A learner-only widget',
      })
    })

    it('returns only educator widgets for educator role', () => {
      const educatorWidgets = getWidgetsForRole(EDUCATOR_WIDGET_ROLE)

      expect(educatorWidgets).toHaveProperty('educator_widget')
      expect(educatorWidgets).not.toHaveProperty('learner_widget')
    })

    it('returns only learner widgets when no role specified', () => {
      const result = getWidgetsForRole()

      expect(result).toHaveProperty('learner_widget')
      expect(result).not.toHaveProperty('educator_widget')
    })
  })

  it('returns a copy of the registry from getAllWidgets', () => {
    const allWidgets1 = getAllWidgets()
    const allWidgets2 = getAllWidgets()

    expect(allWidgets1).not.toBe(allWidgets2)
    expect(allWidgets1).toEqual(allWidgets2)
  })
})
