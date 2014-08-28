define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/models/Folder'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/FileItemView'
  'jst/FolderTreeCollection'
], (Backbone, $, _, preventDefault, Folder, PaginatedCollectionView, FileItemView, collectionTemplate) ->

  class FolderTreeView extends Backbone.View

    tagName: 'li'
    
    @optionProperty 'nestingLevel'
    @optionProperty 'onlyShowFolders'
    @optionProperty 'onClick'
    @optionProperty 'href'

    
    defaults:
      nestingLevel: 1

    attributes: ->
      'role': 'treeitem'
      'aria-expanded': "#{!!@model.isExpanded}"
      'aria-level': @nestingLevel
      id: @tagId

    events:
      'click .folderLabel': 'toggle'

    initialize: ->
      @tagId = _.uniqueId 'treenode-'
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

    title_text: ->
      @model.get('custom_name') || @model.get('name')
      
    renderSelf: ->
      @$el.attr @attributes()
      @$label ||= $("<a class='folderLabel' role='presentation' tabindex='-1' title='#{@title_text()}'/>").prependTo(@$el)
      $text = $('<span>', {
        text: @title_text(),
        click: (event) => @onClick?(event, @model)
      })
      @$label
        .attr('href', @href?(@model) || '#')
        .html($text)
        .toggleClass('expanded', !!@model.isExpanded)
        .toggleClass('loading after', !!@model.isExpanding)

    renderContents: ->
      if @model.isExpanded
        unless @$folderContents
          @$folderContents = $("<ul role='group' class='folderContents'/>").appendTo(@$el)
          foldersView = new PaginatedCollectionView(
            collection: @model.folders
            itemView: FolderTreeView
            itemViewOptions:
              nestingLevel: @nestingLevel+1
              onlyShowFolders: @onlyShowFolders
              onClick: @onClick
              href: @href
            tagName: 'li'
            className: 'folders'
            template: collectionTemplate
            scrollContainer: @$folderContents.closest('ul[role=tabpanel]')
          )
          @$folderContents.append(foldersView.render().el)
          unless @onlyShowFolders
            filesView = new PaginatedCollectionView(
              collection: @model.files
              itemView: FileItemView
              itemViewOptions: {nestingLevel: @nestingLevel+1}
              tagName: 'li'
              className: 'files'
              template: collectionTemplate
              scrollContainer: @$folderContents.closest('ul[role=tabpanel]')
            )
            @$folderContents.append(filesView.render().el)
        @$('> .folderContents').removeClass('hidden')
      else
        @$('> .folderContents').addClass('hidden')

