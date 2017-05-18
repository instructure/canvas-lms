#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'Backbone'
  'compiled/views/content_migrations/MigrationConverterView'
], ($, Backbone, MigrationConverterView) ->
  class SomeBackboneView extends Backbone.View
    className: 'someViewRendered'
    template: -> '<div id="rendered">Rendered</div>'

  QUnit.module 'MigrationConverterView',
    setup: ->
      @clock = sinon.useFakeTimers()
      @migrationConverterView = new MigrationConverterView
        selectOptions:[{id: 'some_converter', label: 'Some Converter'}]
        progressView: new Backbone.View

      $('#fixtures').append @migrationConverterView.render().el

    teardown: ->
      @clock.restore()
      @migrationConverterView.remove()

  test "renders a backbone view into it's main view container", 1, ->
    subView = new SomeBackboneView
    @migrationConverterView.on 'converterRendered', =>
      ok @migrationConverterView.$el.find('#converter #rendered').length > 0, "Rendered a sub view"
    @migrationConverterView.renderConverter subView
    @clock.tick(15)

  test "trigger reset event when no subView is passed in to render", 1, ->
    @migrationConverterView.on 'converterReset', ->
      ok true, "converterReset was called"

    @migrationConverterView.renderConverter()
