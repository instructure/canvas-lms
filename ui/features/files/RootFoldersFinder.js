/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import Folder from '@canvas/files/backbone/models/Folder'
import splitAssetString from '@canvas/util/splitAssetString'

const I18n = useI18nScope('rootFoldersFinder')

function RootFoldersFinder(opts) {
  this.rootFoldersToShow = opts.rootFoldersToShow
  this.contentTypes = opts.contentTypes
  this.useVerifiers = opts.useVerifiers
}

RootFoldersFinder.prototype.find = function () {
  if (this.rootFoldersToShow) {
    return this.rootFoldersToShow
  }
  // purposely sharing these across instances of RootFoldersFinder
  // use a 'custom_name' to set I18n'd names for the root folders (the actual names are hard-coded)
  return (
    RootFoldersFinder.rootFolders ||
    (RootFoldersFinder.rootFolders = (function (_this) {
      return function () {
        let contextFiles = null
        const contextTypeAndId = splitAssetString(ENV.context_asset_string || '')
        if (
          contextTypeAndId &&
          contextTypeAndId.length === 2 &&
          (contextTypeAndId[0] === 'courses' || contextTypeAndId[0] === 'groups')
        ) {
          contextFiles = new Folder({
            contentTypes: _this.contentTypes,
          })
          contextFiles.set(
            'custom_name',
            contextTypeAndId[0] === 'courses'
              ? I18n.t('course_files', 'Course files')
              : I18n.t('group_files', 'Group files')
          )
          contextFiles.url =
            '/api/v1/' + contextTypeAndId[0] + '/' + contextTypeAndId[1] + '/folders/root'
          contextFiles.fetch()
        }
        const myFiles = new Folder({
          contentTypes: _this.contentTypes,
          useVerifiers: _this.useVerifiers,
        })
        myFiles.set('custom_name', I18n.t('my_files', 'My files'))
        myFiles.url = '/api/v1/users/self/folders/root'
        myFiles.fetch()
        const result = []
        if (contextFiles) {
          result.push(contextFiles)
        }
        result.push(myFiles)
        return result
      }
    })(this)())
  )
}

export default RootFoldersFinder
