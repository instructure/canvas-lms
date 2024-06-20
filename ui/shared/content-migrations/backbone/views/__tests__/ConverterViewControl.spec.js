/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import ConverterViewControl from '../ConverterViewControl'

class BackboneSubView extends Backbone.View {
  template() {
    return '<div>Random Backbone View</div>'
  }
}

describe('ConverterViewControlSpec', () => {
  afterEach(() => {
    ConverterViewControl.resetControl()
  })

  test('registering a view adds the view to the register list', () => {
    ConverterViewControl.register({
      value: 'backbone_view',
      view: new BackboneSubView(),
    })
    expect(ConverterViewControl.registeredViews.length).toBe(1)
  })

  test('before registering a view subscribed is false', () => {
    expect(ConverterViewControl.subscribed).toBe(false)
  })

  test('after registering a view subscribed is true', () => {
    ConverterViewControl.register({
      value: 'backbone_view',
      view: new BackboneSubView(),
    })
    expect(ConverterViewControl.subscribed).toBe(true)
  })

  test('resetControl sets subscribed to false if it was true', () => {
    ConverterViewControl.subscribed = true
    ConverterViewControl.resetControl()
    expect(ConverterViewControl.subscribed).toBe(false)
  })

  test('resetControl empties registeredViews list', () => {
    ConverterViewControl.register({
      value: 'backbone_view',
      view: new BackboneSubView(),
    })
    expect(ConverterViewControl.registeredViews.length).toBe(1)
    ConverterViewControl.resetControl()
    expect(ConverterViewControl.registeredViews.length).toBe(0)
  })
})
