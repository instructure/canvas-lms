#
# Copyright (C) 2012 - present Instructure, Inc.
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
  '../models/Folder'
], (Folder) ->

  # `FoldersCollection` is actually defined inside of '../models/Folder'
  # because RequireJS sucks at figuring out circular dependencies.
  # I did exactly what http://requirejs.org/docs/api.html#circular said but the
  # load order was still completely arbitrary. By defining them in the same file
  # we control the load order exactly and things work--consistently.
  return Folder.FoldersCollection
