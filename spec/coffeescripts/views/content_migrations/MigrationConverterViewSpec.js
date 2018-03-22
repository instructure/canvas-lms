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
import Backbone from 'Backbone'
import MigrationConverterView from 'compiled/views/content_migrations/MigrationConverterView'

class SomeBackboneView extends Backbone.View {
  static initClass() {
    this.prototype.className = 'someViewRendered'
  }
  template() {
    return '<div id="rendered">Rendered</div>'
  }
}
SomeBackboneView.initClass()

QUnit.module('MigrationConverterView', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.migrationConverterView = new MigrationConverterView({
      selectOptions: [
        {
          id: 'some_converter',
          label: 'Some Converter'
        }
      ],
      progressView: new Backbone.View()
    })
    return $('#fixtures').append(this.migrationConverterView.render().el)
  },
  teardown() {
    this.clock.restore()
    return this.migrationConverterView.remove()
  }
})

test("renders a backbone view into it's main view container", 1, function() {
  const subView = new SomeBackboneView()
  this.migrationConverterView.on('converterRendered', () =>
    ok(
      this.migrationConverterView.$el.find('#converter #rendered').length > 0,
      'Rendered a sub view'
    )
  )
  this.migrationConverterView.renderConverter(subView)
  return this.clock.tick(15)
})

test('trigger reset event when no subView is passed in to render', 1, function() {
  this.migrationConverterView.on('converterReset', () => ok(true, 'converterReset was called'))
  return this.migrationConverterView.renderConverter()
})
