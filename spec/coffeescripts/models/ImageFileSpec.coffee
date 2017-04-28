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
  'compiled/models/ImageFile'
  'vendor/FileAPI/FileAPI.min'
], (ImageFile, FileAPI) ->

  model = null
  file = {}

  QUnit.module 'ImageFile',
    setup: ->
      model = new ImageFile(null, preflightUrl: '/preflight')
      file = {}
      @stub FileAPI, 'getFiles', -> [file]
      @stub FileAPI, 'filterFiles', (f, cb) ->
        cb(file, file)

    teardown: ->

  test 'returns a useful deferred', ->
    file = {type: "text/plain", size: 1234}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/foo", size: 1234}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/png", size: 123546}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/png", size: 12345}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/png", size: 12345, width: 1000, height: 100}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/png", size: 12345, width: 100, height: 100}
    equal model.loadFile().state(), "resolved"

