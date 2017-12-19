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
  'underscore'
  'Backbone'
  '../collections/PaginatedCollection'
  '../models/WikiPageRevision'
], (_, Backbone, PaginatedCollection, WikiPageRevision) ->

  revisionOptions = ['parentModel']

  class WikiPageRevisionsCollection extends PaginatedCollection
    model: WikiPageRevision

    url: ->
      "#{@parentModel.url()}/revisions"

    initialize: (models, options) ->
      super
      _.extend(this, _.pick(options || {}, revisionOptions))

      if @parentModel
        collection = @
        parentModel = collection.parentModel
        setupModel = (model) ->
          model.page = parentModel
          model.pageUrl = parentModel.get('url')
          model.contextAssetString = parentModel.contextAssetString
          collection.latest = model if !!model.get('latest')

        @on 'reset', (models) ->
          models.each setupModel
        @on 'add', (model) ->
          setupModel(model)
