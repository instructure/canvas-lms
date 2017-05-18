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
  'compiled/views/profiles/AvatarDialogView'
], ($, AvatarDialogView) ->

  QUnit.module 'AvatarDialogView#onPreflight',
    setup: ->
      @avatarDialogView = new AvatarDialogView()
    teardown: ->
      @avatarDialogView = null

  test 'calls flashError with base error message when errors are present', ->
    errorMessage = "User storage quota exceeded"
    @stub(@avatarDialogView, 'enableSelectButton')
    mock = @mock($).expects('flashError').withArgs(errorMessage)
    @avatarDialogView.onPreflight({}, [{responseText:'{"errors":{"base":[{"message":"User storage quota exceeded"}]}}'}])
    ok(mock.verify())

  QUnit.module 'AvatarDialogView#postAvatar',
    setup: ->
      @avatarDialogView = new AvatarDialogView()
    teardown: ->
      @avatarDialogView = null

  test 'calls flashError with base error message when errors are present', ->
    errorMessage = "User storage quota exceeded"
    preflightResponse = {
      upload_url: 'http://some_url',
      upload_params: {},
      file_param: ''
    }
    fakeXhr = {
      responseText: '{"errors":{"base":[{"message":"User storage quota exceeded"}]}}'
    }
    @stub($, 'ajax').yieldsTo('error', fakeXhr)
    mock = @mock($).expects('flashError').withArgs(errorMessage)
    @avatarDialogView.postAvatar(preflightResponse)
    ok(mock.verify())
