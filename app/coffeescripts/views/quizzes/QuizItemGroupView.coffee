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
  'underscore'
  '../CollectionView'
  'jst/quizzes/QuizItemGroupView'
  './QuizItemView'
], ($, _, CollectionView, template, QuizItemView) ->

  class ItemGroupView extends CollectionView
    template: template
    itemView: QuizItemView

    tagName:   'div'
    className: 'item-group-condensed'

    events:
      'click .ig-header .element_toggler': 'clickHeader'

    clickHeader: (e) ->
      $(e.currentTarget).find('i')
        .toggleClass('icon-mini-arrow-down')
        .toggleClass('icon-mini-arrow-right')

    isEmpty: ->
      @collection.isEmpty() or @collection.all((m) -> m.get('hidden'))

    filterResults: (term) =>
      anyChanged = false
      @collection.forEach (model) =>
        hidden = !@filter(model, term)
        if !!model.get('hidden') != hidden
          anyChanged = true
          model.set('hidden', hidden)
      @render() if anyChanged

    matchingCount: (term) =>
      _.select( @collection.models, (m) =>
        @filter(m, term)
      ).length

    filter: (model, term) =>
      return true unless term

      title = model.get('title').toLowerCase()
      numMatches = 0
      keys = term.toLowerCase().split(' ')
      for part in keys
        #not using match to avoid javascript string to regex oddness
        numMatches++ if title.indexOf(part) != -1
      numMatches == keys.length


    render: ->
      super
      @$el.find('.no_content').toggle(@isEmpty())
      @

    renderItem: (model) =>
      return if model.get 'hidden'
      super
