#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'i18n!rootFoldersFinder'
  '../models/Folder'
  '../str/splitAssetString'
], (I18n, Folder, splitAssetString) ->

  class RootFoldersFinder
    constructor: (opts) ->
      @rootFoldersToShow = opts.rootFoldersToShow
      @contentTypes = opts.contentTypes
      @useVerifiers = opts.useVerifiers

    find: ->
      return @rootFoldersToShow if @rootFoldersToShow
      # purposely sharing these across instances of RootFoldersFinder
      # use a 'custom_name' to set I18n'd names for the root folders (the actual names are hard-coded)
      RootFoldersFinder.rootFolders ||= do =>
        contextFiles = null
        contextTypeAndId = splitAssetString(ENV.context_asset_string || '')
        if contextTypeAndId && contextTypeAndId.length == 2 && (contextTypeAndId[0] == 'courses' || contextTypeAndId[0] == 'groups')
          contextFiles = new Folder({contentTypes: @contentTypes})
          contextFiles.set 'custom_name', if contextTypeAndId[0] is 'courses' then I18n.t('course_files', 'Course files') else I18n.t('group_files', 'Group files')
          contextFiles.url = "/api/v1/#{contextTypeAndId[0]}/#{contextTypeAndId[1]}/folders/root"
          contextFiles.fetch()

        myFiles = new Folder({contentTypes: @contentTypes, useVerifiers: @useVerifiers})
        myFiles.set 'custom_name', I18n.t('my_files', 'My files')
        myFiles.url = '/api/v1/users/self/folders/root'
        myFiles.fetch()

        result = []
        result.push contextFiles if contextFiles
        result.push myFiles
        result
