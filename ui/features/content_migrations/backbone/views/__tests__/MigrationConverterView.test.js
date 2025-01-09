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

import $ from 'jquery'
import 'jquery-migrate'
import Backbone from '@canvas/backbone'
import MigrationConverterView from '../MigrationConverterView'

class SomeBackboneView extends Backbone.View {
  static initClass() {
    this.prototype.className = 'someViewRendered'
  }

  template() {
    return '<div id="rendered">Rendered</div>'
  }
}
SomeBackboneView.initClass()

describe('MigrationConverterView', () => {
  let migrationConverterView

  beforeEach(() => {
    jest.useFakeTimers()
    migrationConverterView = new MigrationConverterView({
      selectOptions: [
        {
          id: 'some_converter',
          label: 'Some Converter',
        },
      ],
      progressView: new Backbone.View(),
    })
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('#fixtures').append(migrationConverterView.render().el)
  })

  afterEach(() => {
    jest.useRealTimers()
    migrationConverterView.remove()
    document.body.innerHTML = ''
  })

  it("renders a backbone view into it's main view container", () => {
    const subView = new SomeBackboneView()
    migrationConverterView.on('converterRendered', () => {
      expect(migrationConverterView.$el.find('#converter #rendered').length).toBeGreaterThan(0)
    })
    migrationConverterView.renderConverter(subView)
    jest.advanceTimersByTime(15)
  })

  it('triggers reset event when no subView is passed in to render', () => {
    const resetCallback = jest.fn()
    migrationConverterView.on('converterReset', resetCallback)
    migrationConverterView.renderConverter()
    expect(resetCallback).toHaveBeenCalled()
  })

  it('renders the overwrite warning', () => {
    const subView = new SomeBackboneView()
    migrationConverterView.on('converterRendered', () => {
      expect(migrationConverterView.$el.find('#overwrite-warning').text()).toBe(
        'Importing the same course content more than once will overwrite any existing content in the course.',
      )
    })
    migrationConverterView.renderConverter(subView)
    jest.advanceTimersByTime(15)
  })
})
