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

/* eslint-disable no-void */

import $ from 'jquery'
import {omit} from 'lodash'
import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import splitAssetString from '@canvas/util/splitAssetString'

extend(FilesystemObject, Backbone.Model)

// this is an abstract base class that both File and Folder inherit from.
// they share a little bit of functionality

function FilesystemObject() {
  return FilesystemObject.__super__.constructor.apply(this, arguments)
}

// our API uses a different attribute for the 'name' of Files and Folders
// (`display_name` and `name`, respectively).
// Use this instead of branching when you want to show the name
// and you don't know if it's going to be a file or folder.

FilesystemObject.prototype.displayName = function () {
  return this.get('display_name') || this.get('name')
}

FilesystemObject.prototype.destinationIsSameContext = function (destination) {
  // Verifies that the parent folder of the item being moved
  // belongs to the same context as the destination.
  // If the destination is different, the item is copied/duplicated
  // instead of moved.
  let assetString, ref, ref1, ref2, ref4
  // eslint-disable-next-line no-cond-assign
  const ref3 = (assetString = this.get('context_asset_string'))
    ? splitAssetString(assetString, false)
    : [
        (ref = this.collection.parentFolder) != null ? ref.get('context_type') : void 0,
        (ref1 = this.collection.parentFolder) != null
          ? (ref2 = ref1.get('context_id')) != null
            ? ref2.toString()
            : void 0
          : void 0,
      ]
  const contextType = ref3[0]
  const contextId = ref3[1]
  return (
    contextType &&
    contextId &&
    contextType.toLowerCase() === destination.get('context_type').toLowerCase() &&
    contextId === ((ref4 = destination.get('context_id')) != null ? ref4.toString() : void 0)
  )
}

FilesystemObject.prototype.moveTo = function (newFolder, options) {
  if (options == null) {
    options = {}
  }
  if (this.destinationIsSameContext(newFolder)) {
    return this.moveToFolder(newFolder, options)
  } else {
    return this.copyToContext(newFolder, options)
  }
}

FilesystemObject.prototype.moveToFolder = function (newFolder, options) {
  if (options == null) {
    options = {}
  }
  const attrs = this.setAttributes(
    {
      parent_folder_id: newFolder.id,
    },
    options
  )
  $.extend(attrs, {
    parent_folder_id: newFolder.id,
  })
  return this.save(
    {},
    {
      attrs,
    }
  ).then(
    (function (_this) {
      return function () {
        _this.collection.remove(_this)
        return _this.updateCollection(_this, newFolder, options)
      }
    })(this)
  )
}

FilesystemObject.prototype.copyToContext = function (newFolder, options) {
  if (options == null) {
    options = {}
  }
  const attrs = this.setAttributes($.extend({}, this.attributes), options)
  const type = this.isFile ? 'file' : 'folder'
  attrs['source_' + type + '_id'] = attrs.id
  delete attrs.id
  const clonedModel = new this.constructor(
    omit(attrs, 'id', 'parent_folder_id', 'parent_folder_path')
  )
  const collection = this.updateCollection(clonedModel, newFolder, options)
  clonedModel.url = collection.url
  this.set('url', collection.url)
  const endpoint = 'copy_' + type
  const url = '/api/v1/folders/' + newFolder.attributes.id + '/' + endpoint
  return clonedModel.save(attrs, {
    url,
  })
}

FilesystemObject.prototype.setAttributes = function (attrs, options) {
  if (attrs == null) {
    attrs = {}
  }
  if (options == null) {
    options = {}
  }
  if (options.dup === 'overwrite') {
    $.extend(attrs, {
      on_duplicate: 'overwrite',
    })
  } else if (options.dup === 'rename') {
    if (options.name) {
      $.extend(attrs, {
        display_name: options.name,
        name: options.name,
        on_duplicate: 'rename',
      })
    } else {
      $.extend(attrs, {
        on_duplicate: 'rename',
      })
    }
  }
  return attrs
}

FilesystemObject.prototype.updateCollection = function (model, newFolder, options) {
  // add it to newFolder's children
  const objectType = this.isFile ? 'files' : 'folders' // TODO: find a better way to infer type
  const collection = newFolder[objectType]
  // remove the overwritten object from the collection
  if (options.dup === 'overwrite') {
    collection.remove(
      collection.where({
        display_name: model.get('display_name'),
      })
    )
  }
  collection.add(model, {
    merge: true,
  })
  return collection
}

export default FilesystemObject
