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
  'jquery'
  'Backbone'
  '../feature_flags/FeatureFlagDialog'
  'jst/feature_flags/featureFlag'
], ($, Backbone, FeatureFlagDialog, template) ->

  class FeatureFlagView extends Backbone.View

    tagName: 'li'

    className: 'feature-flag'

    template: template

    els:
      '.element_toggler i': '$detailToggle'

    events:
      'change .ff_button': 'onClickThreeState'
      'change .ff_toggle': 'onClickToggle'
      'click .element_toggler': 'onToggleDetails'
      'keyclick .element_toggler': 'onToggleDetails'

    afterRender: ->
      @$('.ui-buttonset').buttonset()

    onClickThreeState: (e) ->
      $target = $(e.currentTarget)
      action = $target.data('action')
      @applyAction(action)

    onClickToggle: (e) ->
      $target = $(e.currentTarget)
      @applyAction(if $target.is(':checked') then 'on' else 'off')

    onToggleDetails: (e) ->
      @toggleDetailsArrow()

    toggleDetailsArrow: ->
      @$detailToggle.toggleClass('icon-mini-arrow-right')
      @$detailToggle.toggleClass('icon-mini-arrow-down')

    applyAction: (action) ->
      $.when(@canUpdate(action)).then(
        =>
          @model.updateState(action)
        =>
          @render() # undo UI change if user cancels
      )

    canUpdate: (action) ->
      deferred = $.Deferred()
      warning  = @model.warningFor(action)
      return deferred.resolve() if !warning
      view = new FeatureFlagDialog
        deferred: deferred
        message: warning.message
        title: @model.get('display_name')
        hasCancelButton: !warning.locked
      view.render()
      view.show()
      deferred
