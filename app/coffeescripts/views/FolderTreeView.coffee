define [
  'Backbone'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/models/Folder'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/FileItemView'
  'jst/FolderTreeCollection'
], (Backbone, _, preventDefault, Folder, PaginatedCollectionView, FileItemView, collectionTemplate) ->

  class FolderTreeView extends Backbone.View

    tagName: 'li'

    attributes: ->
      'role': 'treeitem'
      'aria-expanded': "#{!!@model.isExpanded}"

    events:
      'click .folderLabel': 'toggle'

    initialize: ->
      @model.on         'all', @render, this
      @model.files.on   'all', @render, this
      @model.folders.on 'all', @render, this
      @render()
      super

    render: ->
      @renderSelf()
      @renderContents()

    toggle: (event) ->
      # prevent it from bubbling up to parents and from following link
      event.preventDefault()
      event.stopPropagation()

      @model.toggle()
      @$el.attr(@attributes())

    title_text: ->
      @model.get('custom_name') || @model.get('name')
      
    renderSelf: ->
      @$label ||= $("<a class='folderLabel' href='#' title='#{@title_text()}'/>").prependTo(@$el)
      @$label
        .text(@title_text())
        .toggleClass('expanded', !!@model.isExpanded)
        .toggleClass('loading after', !!@model.isExpanding)

    renderContents: ->
      if @model.isExpanded
        unless @$folderContents
          @$folderContents = $("<ul role='group' class='folderContents'/>").appendTo(@$el)
          foldersView = new PaginatedCollectionView(
            collection: @model.folders
            itemView: FolderTreeView
            tagName: 'li'
            className: 'folders'
            template: collectionTemplate
            scrollContainer: @$folderContents.closest('ul[role=tabpanel]')
          )
          @$folderContents.append(foldersView.render().el)
          filesView = new PaginatedCollectionView(
            collection: @model.files
            itemView: FileItemView
            tagName: 'li'
            className: 'files'
            template: collectionTemplate
            scrollContainer: @$folderContents.closest('ul[role=tabpanel]')
          )
          @$folderContents.append(filesView.render().el)
        @$('> .folderContents').removeClass('hidden')
      else
        @$('> .folderContents').addClass('hidden')

