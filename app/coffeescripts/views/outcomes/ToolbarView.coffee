#
# Copyright (C) 2012 - present Instructure, Inc.
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
#

define [
  'jquery'
  'underscore'
  'Backbone'
  '../../models/Outcome'
  '../../models/OutcomeGroup'
], ($, _, Backbone, Outcome, OutcomeGroup) ->

  # Manage the toolbar buttons.
  class ToolbarView extends Backbone.View

    events:
      'click .go_back': 'goBack'
      'click .add_outcome_link': 'addOutcome'
      'click .add_outcome_group': 'addGroup'
      'click .import_outcomes': 'importOutcomes'
      'click .find_outcome': 'findDialog'

    goBack: (e) =>
      e.preventDefault()
      @trigger 'goBack'
      $('.add_outcome_link').focus()

    addOutcome: (e) =>
      e.preventDefault()
      model = new Outcome title: ''
      @trigger 'add', model

    addGroup: (e) =>
      e.preventDefault()
      model = new OutcomeGroup title: ''
      @trigger 'add', model

    findDialog: (e) =>
      e.preventDefault()
      @trigger 'find'

    importOutcomes: (e) =>
      e.preventDefault()
      @trigger 'import'

    disable: () =>
      @$el.find('button').each((i, button) =>
        $(button).attr('disabled', 'disabled')
        $(button).attr('aria-disabled', 'true')
      )

    enable: () =>
      @$el.find('button').each((i, button) =>
        $(button).removeAttr('disabled')
        $(button).removeAttr('aria-disabled')
      )

    resetBackButton: (model, directories) =>
      return unless ENV.PERMISSIONS.manage_outcomes
      if model || directories.length > 1
        @$('.go_back').show 200
      else
        @$('.go_back').hide 200
