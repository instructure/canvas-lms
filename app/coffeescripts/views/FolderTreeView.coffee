define [
  'Backbone'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/models/Folder'
  'compiled/views/SharedPaginatedCollectionView'
  'compiled/views/FileItemView'
  'jst/FolderTreeCollection'
], (Backbone, _, preventDefault, Folder, SharedPaginatedCollectionView, FileItemView, collectionTemplate) ->

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
      $focusedChild = @$(document.activeElement)
      @renderSelf()
      @renderContents()
      # restore focus for keyboard users
      @$el.find($focusedChild).focus() if $focusedChild.length

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
          foldersView = new SharedPaginatedCollectionView(
            collection: @model.folders
            itemView: FolderTreeView
            tagName: 'li'
            className: 'folders'
            template: collectionTemplate
            scrollContainer: @$folderContents.closest('ul[role=tabpanel]')
          )
          @$folderContents.append(foldersView.render().el)
          filesView = new SharedPaginatedCollectionView(
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

