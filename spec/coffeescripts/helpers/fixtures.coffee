#
# Copyright (C) 2016 - present Instructure, Inc.
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
  'jsx/shared/rce/RceCommandShim'
], ($, RceCommandShim) ->

  $fixtures = $('#fixtures')

  return {
    setup: (innerHTML='') ->
      $fixtures.innerHTML = innerHTML

    create: (source) ->
      $fixture = $(source)
      $fixtures.append($fixture)
      return $fixture

    find: (selector) ->
      return $(selector, $fixtures)

    teardown: () ->
      # detach any legacy editorBox stuff before removing
      this.find('textarea').each (i, el) ->
        $editor = $(el)
        if ($editor.data('rich_text'))
          RceCommandShim.send($editor, 'destroy')

      $fixtures.empty()
  }
