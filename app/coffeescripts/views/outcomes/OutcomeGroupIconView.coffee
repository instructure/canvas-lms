#
# Copyright (C) 2012 Instructure, Inc.
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
  'str/htmlEscape'
  'compiled/models/Outcome'
  'compiled/views/outcomes/OutcomeIconBase'
  #
  'jquery.disableWhileLoading'
], ($, _, h, Outcome, OutcomeIconBase) ->

  class OutcomeGroupIconView extends OutcomeIconBase

    className: 'outcome-group'
    attributes: _.extend({}, @attributes, 'aria-expanded': false)

    # Internal: Treat right arrow presses like a click.
    #
    # Return nothing.
    onRightArrowKey: (e, $target) ->
      $target.attr('aria-expanded', true).attr('tabindex', -1)
      @triggerSelect()
      setTimeout =>
        $target.parent().next().find('li[tabindex=0]').focus()
      , 1000

    initDroppable: ->
      @$el.droppable
        scope: 'outcomes'
        hoverClass: 'droppable'
        greedy: true
        drop: (e, ui) =>
          model = ui.draggable.data('view').model
          group = if model instanceof Outcome then model.outcomeGroup else model
          # don't re-add to group
          return if group.id is @model.id
          originaldir = @dir.sidebar._findLastDir()
          @triggerSelect() # select to get the directory ready
          disablingDfd = new $.Deferred()
          @dir.$el.disableWhileLoading disablingDfd
          @dir.sidebar.dirForGroup(@model).promise().done (dir) ->
            dir.moveModelHere(model, originaldir).done ->
              disablingDfd.resolve()

    render: ->
      @$el.attr 'data-id', @model.get 'id'
      @$el.html """
          <a href="#" class="ellipsis" title="#{h @model.get('title')}">
            <i class="icon-folder"></i>
            <span>#{h @model.get('title')}</span>
          </a>
        """
      @initDroppable()
      super
