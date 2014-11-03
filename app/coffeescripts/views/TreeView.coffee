define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/TreeItemView'
  'jst/TreeCollection'
], (Backbone, $, _, preventDefault, PaginatedCollectionView, TreeItemView, collectionTemplate) ->

  class TreeView extends Backbone.View

    tagName: 'li'

    @optionProperty 'nestingLevel'
    @optionProperty 'onlyShowSubtrees'
    @optionProperty 'onClick'
    @optionProperty 'dndOptions'
    @optionProperty 'href'
    @optionProperty 'focusStyleClass'
    @optionProperty 'selectedStyleClass'

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
      'selectItem .treeLabel': 'selectItem'

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

        $label = $("""
          <a
            class="treeLabel"
            role="presentation"
            tabindex="-1"
          >
            <i class="icon-mini-arrow-right"></i>
            <i class="icon-folder"></i>
          </a>
        """).append(@$labelInner).prependTo(@$el)

        if @dndOptions
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
            tagName: 'li'
            className: 'subtrees'
            template: collectionTemplate
            scrollContainer: @$treeContents.closest('div[role=tabpanel]')
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
