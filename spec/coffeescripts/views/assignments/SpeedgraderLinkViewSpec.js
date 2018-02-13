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
  'compiled/views/assignments/SpeedgraderLinkView'
  'compiled/models/Assignment'
  'jquery'
  'helpers/assertions'
], (SpeedgraderLinkView, Assignment, $, assertions) ->

  QUnit.module "SpeedgraderLinkView",
    setup: ->
      @model = new Assignment published: false
      $('#fixtures').html """
        <a href="#" id="assignment-speedgrader-link" class="hidden"></a>
      """
      @view = new SpeedgraderLinkView
        model: @model
        el: $('#fixtures').find '#assignment-speedgrader-link'
      @view.render()

    teardown: ->
      @view.remove()
      $('#fixtures').empty()

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @view, done, {'a11yReport': true}

  test "#toggleSpeedgraderLink toggles visibility of speedgrader link on change", ->
    @model.set 'published', true

    ok ! @view.$el.hasClass 'hidden'

    @model.set 'published', false
    ok @view.$el.hasClass 'hidden'
