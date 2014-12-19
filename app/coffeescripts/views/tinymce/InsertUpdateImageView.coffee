define [
  'i18n!editor'
  'jquery'
  'underscore'
  'str/htmlEscape'
  'compiled/fn/preventDefault'
  'compiled/views/DialogBaseView'
  'jst/tinymce/InsertUpdateImageView'
], (I18n, $, _, h, preventDefault, DialogBaseView, template) ->

  class InsertUpdateImageView extends DialogBaseView

    template: template

    events:
      'change [name="image[width]"]' : 'constrainProportions'
      'change [name="image[height]"]' : 'constrainProportions'
      'click .flickrImageResult, .treeFile' : 'onFileLinkClick'
      'change [name="image[src]"]' : 'onImageUrlChange'
      'tabsshow .imageSourceTabs': 'onTabsshow'
      'dblclick .flickrImageResult, .treeFile' : 'onFileLinkDblclick'

    dialogOptions:
      width: 625
      title: I18n.t 'titles.insert_edit_image', 'Insert / Edit Image'

    initialize: (@editor, selectedNode) ->
      @$editor = $("##{@editor.id}")
      @prevSelection = @editor.selection.getBookmark()
      @$selectedNode = $(selectedNode)
      super
      @render()
      @show()
      if @$selectedNode.prop('nodeName') is 'IMG'
        @setSelectedImage
          src: @$selectedNode.attr('src')
          alt: @$selectedNode.attr('alt')
          width: @$selectedNode.width()
          height: @$selectedNode.height()

    afterRender: ->
      @$('.imageSourceTabs').tabs()

    onTabsshow: (event, ui) ->
      loadTab = (fn) =>
        return if @["#{ui.panel.id}IsLoaded"]
        @["#{ui.panel.id}IsLoaded"] = true
        loadingDfd = $.Deferred()
        $(ui.panel).disableWhileLoading loadingDfd
        fn(loadingDfd.resolve)
      switch ui.panel.id
        when 'tabUploaded'
          loadTab (done) =>
            require [
              'compiled/views/TreeBrowserView'
              'compiled/views/RootFoldersFinder'
            ], (TreeBrowserView, RootFoldersFinder) =>
              rootFoldersFinder = new RootFoldersFinder({
                contentTypes: 'image'
              })
              new TreeBrowserView(rootModelsFinder: rootFoldersFinder).render().$el.appendTo(ui.panel)
              done()
        when 'tabFlickr'
          loadTab (done) =>
            require ['compiled/views/FindFlickrImageView'], (FindFlickrImageView) =>
              new FindFlickrImageView().render().$el.appendTo(ui.panel)
              done()

    setAspectRatio: ->
      width = Number @$("[name='image[width]']").val()
      height = Number @$("[name='image[height]']").val()
      if width && height
        @aspectRatio = width / height
      else
        delete @aspectRatio

    constrainProportions: (event) =>
      val = Number $(event.target).val()
      if @aspectRatio && (val or (val is 0))
        if $(event.target).is('[name="image[height]"]')
          @$('[name="image[width]"]').val Math.round(val * @aspectRatio)
        else
          @$('[name="image[height]"]').val Math.round(val / @aspectRatio)

    setSelectedImage: (attributes = {}) ->
      # set given attributes immediately; update width and height after image loads
      @$("[name='image[#{key}]']").val(value) for key, value of attributes
      dfd = $.Deferred()
      onLoad = ({target: img}) =>
        newAttributes = _.defaults attributes,
          width: img.width
          height: img.height
        @$("[name='image[#{key}]']").val(value) for key, value of newAttributes
        isValidImage = newAttributes.width && newAttributes.height
        @setAspectRatio()
        dfd.resolve newAttributes
      onError = ({target: img}) =>
        newAttributes =
          width: ''
          height: ''
        @$("[name='image[#{key}]']").val(value) for key, value of newAttributes
      @$img = $('<img>', attributes).load(onLoad).error(onError)
      dfd

    getAttributes: ->
      res = {}
      for key in ['width', 'height']
        val = Number @$("[name='image[#{key}]']").val()
        res[key] = val if val && val > 0
      for key in ['src',  'alt']
        val = @$("[name='image[#{key}]']").val()
        res[key] = val if val
      res

    onFileLinkClick: (event) ->
      event.preventDefault()
      @$('.active').removeClass('active').parent().removeAttr('aria-selected')
      $a = $(event.currentTarget).addClass('active')
      $a.parent().attr('aria-selected', true)
      @flickr_link = $a.attr('data-linkto')
      @setSelectedImage
        src: $a.attr('data-fullsize')
        alt: $a.attr('title')

    onFileLinkDblclick: (event) =>
      # click event is handled on the first click
      @update()
        
    onImageUrlChange: (event) ->
      @flickr_link = null
      @setSelectedImage src: $(event.currentTarget).val()

    generateImageHtml: ->
      imgHtml = @editor.dom.createHTML("img", @getAttributes())
      if @flickr_link
        imgHtml = "<a href='#{h @flickr_link}'>#{imgHtml}</a>"
      imgHtml
        
    update: =>
      @editor.selection.moveToBookmark(@prevSelection)
      @$editor.editorBox 'insert_code', @generateImageHtml()
      @editor.focus()
      @close()
