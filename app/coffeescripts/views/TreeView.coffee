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
    @optionProperty 'onlyShowFolders'
    @optionProperty 'onClick'
    @optionProperty 'dndOptions'
    @optionProperty 'href'
    @optionProperty 'focusStyleClass'
    @optionProperty 'selectedStyleClass'

    defaults:
      nestingLevel: 1

    attributes: ->
      'role': 'treeitem'
      'aria-expanded': "#{!!@model.isExpanded}"
      'aria-level': @nestingLevel
      id: @tagId

    events:
      'click .folderLabel': 'toggle'
      'selectItem .folderLabel': 'selectItem'

    initialize: ->
      @tagId = _.uniqueId 'treenode-'
      @render = _.debounce(@render)
      @model.on         'all', @render, this
      @model.files.on   'all', @render, this
      @model.folders.on 'all', @render, this
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

      @model.toggle({onlyShowFolders: @onlyShowFolders})
      @$el.attr(@attributes())

    selectItem: (event) ->
      $span = $(event.target).find('span')
      $span.trigger('click')

    title_text: ->
      @model.get('custom_name') || @model.get('name')

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
            class="folderLabel"
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

      # Let's this work well with file browsers like New Files
      if (@selectedStyleClass)
        @$label.toggleClass(@selectedStyleClass, window.location.pathname is @href?(@model))

    renderContents: ->
      if @model.isExpanded
        unless @$folderContents
          @$folderContents = $("<ul role='group' class='folderContents'/>").appendTo(@$el)
          # TODO: make the scrollContainer generic, not specific to a certain
          # type of modal dialog
          subtreesView = new PaginatedCollectionView(
            collection: @model.folders
            itemView: TreeView
            itemViewOptions:
              nestingLevel: @nestingLevel+1
              onlyShowFolders: @onlyShowFolders
              onClick: @onClick
              dndOptions: @dndOptions
              href: @href
              focusStyleClass: @focusStyleClass
              selectedStyleClass: @selectedStyleClass
            tagName: 'li'
            className: 'folders'
            template: collectionTemplate
            scrollContainer: @$folderContents.closest('div[role=tabpanel]')
          )
          @$folderContents.append(subtreesView.render().el)
          unless @onlyShowFolders
            # TODO: make the scrollContainer generic, not specific to a certain
            # type of modal dialog
            itemsView = new PaginatedCollectionView(
              collection: @model.files
              itemView: TreeItemView
              itemViewOptions: {nestingLevel: @nestingLevel+1}
              tagName: 'li'
              className: 'files'
              template: collectionTemplate
              scrollContainer: @$folderContents.closest('div[role=tabpanel]')
            )
            @$folderContents.append(itemsView.render().el)
        @$('> .folderContents').removeClass('hidden')
      else
        @$('> .folderContents').addClass('hidden')

