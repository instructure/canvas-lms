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
  'i18n!assignments'
  'jquery'
  'Backbone'
  'jst/MoveDialogSelect'
], (I18n, $, Backbone, template) ->

  class MoveDialogSelect extends Backbone.View
    setViewProperties: false
    @optionProperty 'lastList'
    @optionProperty 'excludeModel'
    @optionProperty 'labelText'

    className: 'move_select'
    template: template

    getLabelText: ->
      @labelText or
      I18n.beforeLabel I18n.t('labels.label_place_before', "Place before")

    initialize: (options) ->
      super
      if @model and not @collection
        @collection = @model.collection if @model.collection

    setCollection: (coll) ->
      return unless coll
      @collection = coll
      @renderOptions()

    renderOptions: ->
      # I'm sorry, Voiceover + jQueryUI made me do it
      # VO won't acknowledge the existance of the re-rendered view
      # but if we render just the options, it's OK
      $fragment = $(@template @toJSON())
      $opts = $fragment.filter('select').find('option')
      @$('select').empty().append($opts)

    value: ->
      @$('select').val()

    toJSON: ->
      data = @model.toView?() or @model.toJSON()

      data.lastList = @lastList
      data.labelText = @getLabelText()
      data.items =
        if @excludeModel
          @collection.reject((m) =>
            @model.id == m.id
          ).map (m) -> m.toView?() or m.toJSON()
        else
          @collection.toJSON()
      data
