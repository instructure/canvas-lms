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
  'i18n!outcomes'
  'Backbone'
  'underscore'
  '../CollectionView'
  './OutcomeView'
  'jst/grade_summary/group'
], (I18n, {View, Collection}, _, CollectionView, OutcomeView, template) ->

  class GroupView extends View
    tagName: 'li'
    className: 'group'

    els:
      '.outcomes': '$outcomes'

    events:
      'click .group-description': 'expand'
      'keyclick .group-description': 'expand'

    template: template

    render: ->
      super
      outcomesView = new CollectionView
        el: @$outcomes
        collection: @model.get('outcomes')
        itemView: OutcomeView
      outcomesView.render()

    expand: ->
      @$el.toggleClass('expanded')
      if @$el.hasClass("expanded")
        @$el.children("div.group-description").attr("aria-expanded", "true")
      else
        @$el.children("div.group-description").attr("aria-expanded", "false")

      $collapseToggle = $('div.outcome-toggles a.icon-collapse')
      if $('li.group.expanded').length == 0
        $collapseToggle.attr('disabled', 'disabled')
        $collapseToggle.attr('aria-disabled', 'true')
      else
        $collapseToggle.removeAttr('disabled')
        $collapseToggle.attr('aria-disabled', 'false')

      $expandToggle = $('div.outcome-toggles a.icon-expand')
      if $('li.group:not(.expanded)').length == 0
        $expandToggle.attr('disabled', 'disabled')
        $expandToggle.attr('aria-disabled', 'true')
      else
        $expandToggle.removeAttr('disabled')
        $expandToggle.attr('aria-disabled', 'false')

    statusTooltip: ->
      switch @model.status()
        when 'undefined' then I18n.t('Unstarted')
        when 'remedial' then I18n.t('Well Below Mastery')
        when 'near' then I18n.t('Near Mastery')
        when 'mastery' then I18n.t('Meets Mastery')
        when 'exceeds' then I18n.t('Exceeds Mastery')

    toJSON: ->
      json = super
      _.extend json,
        statusTooltip: @statusTooltip()
