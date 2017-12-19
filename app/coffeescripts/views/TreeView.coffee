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

define [
  'Backbone'
  'jquery'
  'underscore'
  '../fn/preventDefault'
  './PaginatedCollectionView'
  './TreeItemView'
  'jst/TreeCollection'
  'str/htmlEscape'
], (Backbone, $, _, preventDefault, PaginatedCollectionView, TreeItemView, collectionTemplate, htmlEscape) ->

  class TreeView extends Backbone.View

    tagName: 'li'

    @optionProperty 'nestingLevel'
    @optionProperty 'onlyShowSubtrees'
    @optionProperty 'onClick'
    @optionProperty 'dndOptions'
    @optionProperty 'href'
    @optionProperty 'focusStyleClass'
    @optionProperty 'selectedStyleClass'
    @optionProperty 'autoFetch'
    @optionProperty 'fetchItAll'

    defaults:
      nestingLevel: 1

    attributes: ->
      'role': 'treeitem'
      'data-id': @model.id
      'aria-expanded': "#{!!@model.isExpanded}"
      'aria-level': @nestingLevel
      'aria-label': @model.get('custom_name') || @model.get('name') || @model.get('title')
      id: @tagId

    events:
      'click .treeLabel': 'toggle'
      'selectItem .treeFile, .treeLabel': 'selectItem'

    initialize: ->
      @tagId = _.uniqueId 'treenode-'
      @render = _.debounce(@render)
      @model.on         'all', @render, this
      @model.getItems().on   'all', @render, this
      @model.getSubtrees().on 'all', @render, this
      res = super
      @render()
      res

    render: ->
      @renderSelf()
      @renderContents()

    toggle: (event) ->
      # prevent it from bubbling up to parents and from following link
      event.preventDefault()
      event.stopPropagation()

      @model.toggle({onlyShowSubtrees: @onlyShowSubtrees})
      @$el.attr(@attributes())

    selectItem: (event) ->
      $span = $(event.target).find('span')
      $span.trigger('click')

    title_text: ->
      @model.get('custom_name') || @model.get('name') || @model.get('title')

    renderSelf: ->
      return if @model.isNew()
      @$el.attr @attributes()
      @$label ||= do =>
        @$labelInner = $('<span>').click (event) =>
          if (@selectedStyleClass)
            $('.' + _this.selectedStyleClass).each((key, element) => $(element).removeClass(@selectedStyleClass))
            $(event.target).addClass(@selectedStyleClass)
          @onClick?(event, @model)
        icon_class = if @model.get('for_submissions') then 'icon-folder-locked' else 'icon-folder'
        $label = $("""
          <a
            class="treeLabel"
            role="presentation"
            tabindex="-1"
          >
            <i class="icon-mini-arrow-right"></i>
            <i class="#{htmlEscape(icon_class)}"></i>
          </a>
        """).append(@$labelInner).prependTo(@$el)

        if @dndOptions && !@model.get('for_submissions')
          toggleActive = (makeActive) ->
            return -> $label.toggleClass('activeDragTarget', makeActive)
          $label.on
            'dragenter dragover': (event) =>
              @dndOptions.onItemDragEnterOrOver(event.originalEvent, toggleActive(true))
            'dragleave dragend': (event) =>
              @dndOptions.onItemDragLeaveOrEnd(event.originalEvent, toggleActive(false))
            'drop': (event) =>
              @dndOptions.onItemDrop(event.originalEvent, @model, toggleActive(false))

        return $label

      @$labelInner.text(@title_text())
      @$label
        .attr('href', @href?(@model) || '#')
        .toggleClass('expanded', !!@model.isExpanded)
        .toggleClass('loading after', !!@model.isExpanding)

      # Lets this work well with file browsers like New Files
      if (@selectedStyleClass)
        @$label.toggleClass(@selectedStyleClass, window.location.pathname is @href?(@model))

    renderContents: ->
      if @model.isExpanded
        unless @$treeContents
          @$treeContents = $("<ul role='group' class='treeContents'/>").appendTo(@$el)
          subtreesView = new PaginatedCollectionView(
            collection: @model.getSubtrees()
            itemView: TreeView
            itemViewOptions:
              nestingLevel: @nestingLevel+1
              onlyShowSubtrees: @onlyShowSubtrees
              onClick: @onClick
              dndOptions: @dndOptions
              href: @href
              focusStyleClass: @focusStyleClass
              selectedStyleClass: @selectedStyleClass
              autoFetch: @autoFetch
              fetchItAll: @fetchItAll
            tagName: 'li'
            className: 'subtrees'
            template: collectionTemplate
            scrollContainer: @$treeContents.closest('div[role=tabpanel]')
            autoFetch: @autoFetch
            fetchItAll: @fetchItAll
          )
          @$treeContents.append(subtreesView.render().el)
          unless @onlyShowSubtrees
            itemsView = new PaginatedCollectionView(
              collection: @model.getItems()
              itemView: TreeItemView
              itemViewOptions: {nestingLevel: @nestingLevel+1}
              tagName: 'li'
              className: 'items'
              template: collectionTemplate
              scrollContainer: @$treeContents.closest('div[role=tabpanel]')
            )
            @$treeContents.append(itemsView.render().el)
        @$('> .treeContents').removeClass('hidden')
      else
        @$('> .treeContents').addClass('hidden')
