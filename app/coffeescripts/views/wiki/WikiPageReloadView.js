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
], (_, Backbone) ->

  pageReloadOptions = ['reloadMessage', 'warning', 'interval']

  class WikiPageReloadView extends Backbone.View
    setViewProperties: false
    template: -> "<div class='alert alert-#{$.raw if @options.warning then 'warning' else 'info'} reload-changed-page'>#{$.raw @reloadMessage}</div>"

    defaults:
      modelAttributes: ['title', 'url', 'body']
      warning: false

    events:
      'click a.reload': 'reload'

    initialize: (options) ->
      super
      _.extend(this, _.pick(options || {}, pageReloadOptions))

    pollForChanges: ->
      return unless @model

      view = @
      model = @model
      latestRevision = @latestRevision = model.latestRevision()
      if latestRevision && !model.isNew()
        latestRevision.on 'change:revision_id', ->
          # when the revision changes, query the full record
          latestRevision.fetch(data: {summary: false}).done ->
            view.render()
            view.trigger('changed')
            view.stopPolling()

        latestRevision.pollForChanges(@interval)

    stopPolling: ->
      @latestRevision?.stopPolling()

    reload: (ev) ->
      ev?.preventDefault()
      @model.set(_.pick(@latestRevision.attributes, @options.modelAttributes))
      @trigger('reload')
      @latestRevision.startPolling()
