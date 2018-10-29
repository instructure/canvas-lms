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
//

import PaginatedCollection from '../collections/PaginatedCollection'
import _ from 'underscore'
import File from '../models/File'

export default class FilesCollection extends PaginatedCollection {
  initialize() {
    this.on('change:sort change:order', this.setQueryStringParams)
    return super.initialize(...arguments)
  }

  fetch(options = {}) {
    let res
    options.data = _.extend(
      {content_types: this.parentFolder != null ? this.parentFolder.contentTypes : undefined},
      options.data || {}
    )
    if (this.parentFolder != null ? this.parentFolder.useVerifiers : undefined) {
      options.data.use_verifiers = 1
    }
    return (res = super.fetch(options))
  }

  parse(response) {
    if (response && this.parentFolder) {
      const previewUrl = this.parentFolder.previewUrl()
      _.each(
        response,
        file =>
          (file.rce_preview_url = previewUrl
            ? previewUrl.replace('{{id}}', file.id.toString())
            : file.url)
      )
    }
    return super.parse(...arguments)
  }

  // TODO: This is duplicate code from Folder.coffee, can we DRY?
  setQueryStringParams() {
    const newParams = {
      include: ['user'],
      per_page: 20,
      sort: this.get('sort'),
      order: this.get('order')
    }

    if (this.loadedAll) return
    const url = new URL(this.url)
    const params = deparam(url.search)
    url.search = $.param(_.extend(params, newParams))
    this.url = url.toString()
    return this.reset()
  }
}
FilesCollection.optionProperty('parentFolder')

FilesCollection.prototype.model = File
