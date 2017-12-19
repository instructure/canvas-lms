#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'underscore'
  'Backbone'
  '../CollectionView'
  './SectionView'
  './OutcomeDetailView'
], ($, _, Backbone, CollectionView, SectionView, OutcomeDetailView) ->
  class OutcomeSummaryView extends CollectionView
    @optionProperty 'toggles'

    itemView: SectionView

    initialize: ->
      super
      @outcomeDetailView = new OutcomeDetailView()
      @bindToggles()

    show: (path) ->
      @fetch()
      if path
        outcome_id = parseInt(path)
        outcome = @collection.outcomeCache.get(outcome_id)
        @outcomeDetailView.show(outcome) if outcome
      else
        @outcomeDetailView.close()

    fetch: ->
      @fetch = $.noop
      @collection.fetch()

    bindToggles: ->
      $collapseToggle = $('div.outcome-toggles a.icon-collapse')
      $expandToggle = $('div.outcome-toggles a.icon-expand')
      @toggles.find('.icon-expand').click =>
        @$('li.group').addClass('expanded')
        @$('div.group-description').attr('aria-expanded', "true")
        $expandToggle.attr('disabled', 'disabled')
        $expandToggle.attr('aria-disabled', 'true')
        $collapseToggle.removeAttr('disabled')
        $collapseToggle.attr('aria-disabled', 'false')
        $("div.groups").focus()
      @toggles.find('.icon-collapse').click =>
        @$('li.group').removeClass('expanded')
        @$('div.group-description').attr('aria-expanded', "false")
        $collapseToggle.attr('disabled', 'disabled')
        $collapseToggle.attr('aria-disabled', 'true')
        $expandToggle.removeAttr('disabled')
        $expandToggle.attr('aria-disabled', 'false')
