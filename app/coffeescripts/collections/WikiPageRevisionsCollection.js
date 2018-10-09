//
// Copyright (C) 2013 - present Instructure, Inc.
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

import _ from 'underscore'
import PaginatedCollection from '../collections/PaginatedCollection'
import WikiPageRevision from '../models/WikiPageRevision'

const revisionOptions = ['parentModel']

export default class WikiPageRevisionsCollection extends PaginatedCollection {
  url() {
    return `${this.parentModel.url()}/revisions`
  }

  initialize(models, options) {
    super.initialize(...arguments)
    _.extend(this, _.pick(options || {}, revisionOptions))

    if (this.parentModel) {
      const collection = this
      const {parentModel} = collection

      function setupModel(model) {
        model.page = parentModel
        model.pageUrl = parentModel.get('url')
        model.contextAssetString = parentModel.contextAssetString
        if (model.get('latest')) {
          collection.latest = model
        }
      }

      this.on('reset', models => models.each(setupModel))
      this.on('add', model => setupModel(model))
    }
  }
}
WikiPageRevisionsCollection.prototype.model = WikiPageRevision
