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
  '../models/WikiPageRevision'
  '../models/Assignment'
  '../backbone-ext/DefaultUrlMixin'
  '../str/splitAssetString'
  'i18n!pages'
], (_, Backbone, WikiPageRevision, Assignment, DefaultUrlMixin,
    splitAssetString, I18n) ->

  pageOptions = ['contextAssetString', 'revision']

  class WikiPage extends Backbone.Model
    @mixin DefaultUrlMixin
    resourceName: 'pages'
    idAttribute: 'page_id'

    initialize: (attributes, options) ->
      super
      Object.assign(this, _.pick(options || {}, pageOptions))
      [@contextName, @contextId] = splitAssetString(@contextAssetString) if @contextAssetString

      @on 'change:front_page', @setPublishable
      @on 'change:published', @setPublishable
      @setPublishable()

    setPublishable: ->
      front_page = @get('front_page')
      published = @get('published')
      publishable = !front_page || !published
      deletable = !front_page
      @set('publishable', publishable)
      @set('deletable', deletable)
      if publishable
        @unset('publishableMessage')
      else
        @set('publishableMessage', I18n.t('cannot_unpublish_front_page', 'Cannot unpublish the front page'))

    disabledMessage: ->
      @get('publishableMessage')

    urlRoot: ->
      "/api/v1/#{@_contextPath()}/pages"

    url: ->
      if @get('url') then "#{@urlRoot()}/#{@get('url')}" else @urlRoot()

    latestRevision: (options) ->
      if !@_latestRevision && @get('url')
        unless @_latestRevision
          revisionOptions = Object.assign({}, {@contextAssetString, page: @, pageUrl: @get('url'), latest: true, summary: true}, options)
          @_latestRevision = new WikiPageRevision({revision_id: @revision}, revisionOptions)
      @_latestRevision

    # Flatten the nested data structure required by the api (see @publish and @unpublish)
    parse: (response, options) ->
      if response.wiki_page
        response = _.extend _.omit(response, 'wiki_page'), response.wiki_page
      response.set_assignment = response.assignment?
      assign_attributes = response.assignment || {}
      response.assignment = @createAssignment(assign_attributes)
      response

    createAssignment: (attributes) ->
      a = new Assignment(attributes)
      a.alreadyScoped = true
      a

    # Gives a json representation of the model
    toJSON: ->
      json = super
      delete json.assignment unless json.set_assignment
      json.assignment = json.assignment?.toJSON()

      wiki_page:
        json

    # Returns a json representation suitable for presenting
    present: ->
      Object.assign {}, @attributes, contextName: @contextName, contextId: @contextId, new_record: !@get('url')

    duplicate: (courseId, callback) ->
      $.ajaxJSON "/api/v1/courses/#{courseId}/pages/#{@id}/duplicate", 'POST',
        {}, callback

    # Uses the api to perform a publish on the page
    publish: ->
      attrs =
        wiki_page:
          published: true
      @save attrs, attrs: attrs, wait: true

    # Uses the api to perform an unpublish on the page
    unpublish: ->
      attrs =
        wiki_page:
          published: false
      @save attrs, attrs: attrs, wait: true

    # Uses the api to set the page as the front page
    setFrontPage: (callback) ->
      attrs =
        wiki_page:
          front_page: true
      @save attrs, attrs: attrs, wait: true, complete: callback

    # Uses the api to unset the page as the front page
    unsetFrontPage: ->
      attrs =
        wiki_page:
          front_page: false
      @save attrs, attrs: attrs, wait: true
