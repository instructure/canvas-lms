define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/TreeItemView'
  'jst/TreeCollection'
  'compiled/str/TextHelper'
], (Backbone, $, _, preventDefault, PaginatedCollectionView, TreeItemView, collectionTemplate, textHelper) ->

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
      @truncateLinks()

    truncateLinks: ->
      truncLength = 37
      items = @$('.truncate')
      items.each ->
        $this = $(this)
        the_text = $this.text()
        $this.attr('data-tooltip', '')

        # only truncate text that hasn't already been truncated
        # This is neccessary because the "render" function calls each node once,
        # then a final render with all of the nodes. Yikes.
        if (the_text.length > truncLength)
          truncateText = textHelper.truncateText(the_text, {max: truncLength})
          $this.text(truncateText)
          $this.attr('title', the_text)

        # Handles any folders that didn't get a tooltip added to them
        $this.attr('title', the_text) unless $this.attr('title')?

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
        @$labelInner.addClass('truncate')

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
