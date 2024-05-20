//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import FilesystemObject from './FilesystemObject'
import identityMapMixin from '../../util/backboneIdentityMap'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import FilesCollection from '../collections/FilesCollection'
import natcompare from '@canvas/util/natcompare'

// `full_name` will be something like "course files/some folder/another".
// For routing in the react app in the browser, we want something that will take that "course files"
// out. because urls will end up being /courses/2/files/folder/some folder/another
const EVERYTHING_BEFORE_THE_FIRST_SLASH = /^[^\/]+\/?/
let filesEnv = null

function getSortProp(model, sortProp) {
  // if we are sorting by name use 'display_name' for files and 'name' for folders.
  if (sortProp === 'name' && !(model instanceof Folder)) {
    return model.get('display_name')
  } else if (sortProp === 'user') {
    return __guard__(model.get('user'), x => x.display_name) || ''
  } else if (sortProp === 'usage_rights') {
    return __guard__(model.get('usage_rights'), x1 => x1.license_name) || ''
  } else {
    return model.get(sortProp)
  }
}

class __Folder extends FilesystemObject {
  initialize(options) {
    if (!this.contentTypes) this.contentTypes = options != null ? options.contentTypes : undefined
    if (!this.useVerifiers) this.useVerifiers = options != null ? options.useVerifiers : undefined
    this.setUpFilesAndFoldersIfNeeded()
    this.on('change:sort change:order', this.setQueryStringParams)
    return super.initialize(...arguments)
  }

  url() {
    if (this.isNew()) {
      return super.url(...arguments)
    } else {
      return `/api/v1/folders/${this.id}`
    }
  }

  parse(response) {
    const json = super.parse(...arguments)
    if (!this.contentTypes) this.contentTypes = response.contentTypes
    if (!this.useVerifiers) this.useVerifiers = response.useVerifiers
    this.setUpFilesAndFoldersIfNeeded()

    this.folders.url = response.folders_url
    this.files.url = response.files_url

    return json
  }

  setUpFilesAndFoldersIfNeeded() {
    if (!this.folders) {
      this.folders = new FoldersCollection([], {parentFolder: this})
    }
    if (!this.files) {
      return (this.files = new FilesCollection([], {parentFolder: this}))
    }
  }

  getSubtrees() {
    return this.folders
  }

  getItems() {
    return this.files
  }

  expand(force = false, options = {}) {
    let fetchDfd
    this.isExpanded = true
    this.trigger('expanded')
    if (this.expandDfd || force) {
      return $.when()
    }
    this.isExpanding = true
    this.trigger('beginexpanding')
    this.expandDfd = $.Deferred().done(() => {
      this.isExpanding = false
      return this.trigger('endexpanding')
    })

    const selfHasntBeenFetched =
      this.folders.url === this.folders.constructor.prototype.url ||
      this.files.url === this.files.constructor.prototype.url
    if (selfHasntBeenFetched || force) {
      fetchDfd = this.fetch()
    }
    return $.when(fetchDfd).done(() => {
      let filesDfd, foldersDfd
      if (this.get('folders_count') !== 0) {
        foldersDfd = this.folders.fetch({data: {per_page: this.get('folders_count')}})
      }
      if (this.get('files_count') !== 0 && !options.onlyShowSubtrees) {
        filesDfd = this.files.fetch()
      }
      return $.when(foldersDfd, filesDfd).done(this.expandDfd.resolve)
    })
  }

  collapse() {
    this.isExpanded = false
    return this.trigger('collapsed')
  }

  toggle(options) {
    if (this.isExpanded) {
      return this.collapse()
    } else {
      return this.expand(false, options)
    }
  }

  previewUrl() {
    let needle
    if (((needle = this.get('context_type')), ['Course', 'Group'].includes(needle))) {
      return `/${`${this.get('context_type').toLowerCase()}s`}/${this.get(
        'context_id'
      )}/files/{{id}}/preview`
    }
  }

  isEmpty() {
    return (
      !!(this.files.loadedAll && this.files.length === 0) &&
      this.folders.loadedAll &&
      this.folders.length === 0
    )
  }

  urlPath() {
    let relativePath = (this.get('full_name') || '').replace(EVERYTHING_BEFORE_THE_FIRST_SLASH, '')
    relativePath = relativePath.replace(/%/g, '&#37;')
    relativePath = relativePath
      .split('/')
      .map(component => encodeURIComponent(component))
      .join('/')

    if (!filesEnv) filesEnv = require('../../react/modules/filesEnv').default // circular dep

    // when we are viewing all files we need to pad the context_asset_string on the front of the url
    // so it would be something like /files/folder/users_1/some/sub/folder
    if (filesEnv.showingAllContexts) {
      const assetString = `${__guard__(this.get('context_type'), x => x.toLowerCase())}s_${this.get(
        'context_id'
      )}`
      relativePath = `${assetString}/${relativePath}`
    }

    return relativePath
  }

  // #
  // Special sorter for handling sorting with special properties
  // It's been enhanced to sort naturally when certain sortProps
  // are used.
  childrenSorter(sortProp = 'name', sortOrder = 'asc', a, b) {
    // Only use natural mode for instances we expect strings in.
    let res
    const naturalMode = ['name', 'user', 'usage_rights'].includes(sortProp)

    // Get actual values for the properties we are sorting by.
    a = getSortProp(a, sortProp)
    b = getSortProp(b, sortProp)

    if (naturalMode) {
      res = natcompare.strings(a, b)
    } else {
      res = (() => {
        if (a === b) {
          return 0
        } else if (a > b || a === undefined) {
          return 1
        } else if (a < b || b === undefined) {
          return -1
        } else {
          throw new Error('wat? error sorting')
        }
      })()
    }

    if (sortOrder === 'desc') {
      res = 0 - res
    }
    return res
  }

  children({sort, order}) {
    return this.folders
      .toArray()
      .concat(this.files.toArray())
      .sort(this.childrenSorter.bind(null, sort, order))
  }
}
__Folder.resolvePath = function (contextType, contextId, folderPath) {
  folderPath = folderPath
    .split('/')
    .map(component => encodeURIComponent(decodeURIComponent(component).replace(/&#37;/, '%')))
    .join('/')

  const url = `/api/v1/${contextType}/${contextId}/folders/by_path${folderPath}`
  return $.getJSON(url).pipe(folders =>
    folders.map(folderAttrs => new Folder(folderAttrs, {parse: true}))
  )
}

__Folder.prototype.defaults = {name: ''}

const Folder = identityMapMixin(__Folder)
export default Folder

class FoldersCollection extends PaginatedCollection {
  static initClass() {
    this.optionProperty('parentFolder')
    this.prototype.model = Folder
  }

  parse(response) {
    if (response) {
      response.forEach(folder => {
        folder.contentTypes = this.parentFolder.contentTypes
        return (folder.useVerifiers = this.parentFolder.useVerifiers)
      })
    }
    return super.parse(...arguments)
  }
}
FoldersCollection.initClass()

// FoldersCollection is defined inside of this file, and not where it
// should be, because RequireJS sucks at figuring out circular dependencies.
// '../collections/FoldersCollection' just grabs this and re-exports it.
Folder.FoldersCollection = FoldersCollection

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
