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
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageDeleteDialog'
], (WikiPage, WikiPageDeleteDialog) ->

  QUnit.module 'WikiPageDeleteDialog'

  test 'maintains the view of the model', ->
    model = new WikiPage
    model.view = view = {}
    dialog = new WikiPageDeleteDialog
      model: model

    equal model.view, view, 'model.view is unaltered'
