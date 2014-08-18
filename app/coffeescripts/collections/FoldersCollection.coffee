#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'require'
  'underscore'
  'Backbone'
  'compiled/collections/PaginatedCollection'
  'compiled/models/Folder'
], (require, _, Backbone, PaginatedCollection, _THIS_WILL_BE_NULL_) ->

  class FoldersCollection extends PaginatedCollection
    @optionProperty 'parentFolder'

    # this breaks the circular dependency between Folder <-> FoldersCollection
    require ['compiled/models/Folder'], (Folder) ->
      FoldersCollection::model = Folder

    parse: (response) ->
      if response
        _.each response, (folder) =>
          folder.contentTypes = @parentFolder.contentTypes
      super
