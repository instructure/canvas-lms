define [
  'Backbone'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/models/Folder'
  'jst/FolderTreeItem'
], (Backbone, _, preventDefault, Folder, treeItemTemplate) ->

  class FolderTreeView extends Backbone.View

    tagName: 'li'

    attributes: ->
      'role': 'treeitem'
      'aria-expanded': "#{!!@model.isExpanded}"

    events:
      'click .folderLabel': 'toggle'

    # you can set an optional `@options.contentTypes` attribute with an array of
    # content-types files that you want to show
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
      @$folderContents?.detach()
      if @model.isExpanded
        @$folderContents = $("<ul role='group' />").appendTo(@$el)
        _.each @model.contents(), (model) =>
          node = @["viewFor_#{model.cid}"] ||=
            if model.constructor is Folder
              # recycle DOM nodes to prevent zombies that still respond to model events,
              # sad that I have to attach something to the model though
              new FolderTreeView(
                model: model
                contentTypes: @options.contentTypes
              ).el
            else if !@options.contentTypes || (model.get('content-type') in @options.contentTypes)
              $ treeItemTemplate
                title: model.get 'display_name'
                thumbnail_url: model.get 'thumbnail_url'
                preview_url: @model.previewUrlForFile(model)
          @$folderContents.append node if node
