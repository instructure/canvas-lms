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
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageContentView'
], ($, WikiPage, WikiPageContentView) ->

  QUnit.module 'WikiPageContentView'

  test 'setModel causes a re-render', ->
    wikiPage = new WikiPage
    contentView = new WikiPageContentView
    @mock(contentView).expects('render').atLeast(1)
    contentView.setModel(wikiPage)

  test 'setModel binds to the model change:title trigger', ->
    wikiPage = new WikiPage
    contentView = new WikiPageContentView
    contentView.setModel(wikiPage)
    @mock(contentView).expects('render').atLeast(1)
    wikiPage.set('title', 'A New Title')

  test 'setModel binds to the model change:title trigger', ->
    wikiPage = new WikiPage
    contentView = new WikiPageContentView
    contentView.setModel(wikiPage)
    @mock(contentView).expects('render').atLeast(1)
    wikiPage.set('body', 'A New Body')

  test 'render publishes a "userContent/change" (to enhance user content)', ->
    contentView = new WikiPageContentView
    $.subscribe('userContent/change', @mock().atLeast(1))
    contentView.render()
