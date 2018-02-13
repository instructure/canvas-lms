#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'helpers/assertions'
  'compiled/views/DiscussionTopic/DiscussionTopicToolbarView'
], ($, assertions, DiscussionTopicToolbarView) ->

  fixture = """
  <div id="discussion-topic-toolbar">
    <div id="keyboard-shortcut-modal-info" tabindex="0">
      <span class="accessibility-warning" style="display: none;"></span>
    </div>
  </div>
  """

  QUnit.module 'DiscussionTopicToolbarView',
    setup: ->
      $('#fixtures').html(fixture)
      @view = new DiscussionTopicToolbarView(el: '#discussion-topic-toolbar')
      @info = @view.$('#keyboard-shortcut-modal-info .accessibility-warning')

    teardown: ->
      $('#fixtures').empty()

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @view, done, {'a11yReport': true}

  test 'keyboard shortcut modal info shows when it has focus', ->
    ok @info.css('display') is 'none'
    @view.$('#keyboard-shortcut-modal-info').focus()
    ok @info.css('display') isnt 'none'

  test 'keyboard shortcut modal info hides when it loses focus', ->
    @view.$('#keyboard-shortcut-modal-info').focus()
    ok @info.css('display') isnt 'none'
    @view.$('#keyboard-shortcut-modal-info').blur()
    ok @info.css('display') is 'none'
