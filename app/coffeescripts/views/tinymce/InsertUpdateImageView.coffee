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
  'i18n!editor'
  'jquery'
  'underscore'
  'str/htmlEscape'
  '../../fn/preventDefault'
  '../DialogBaseView'
  'jst/tinymce/InsertUpdateImageView'
  'jsx/shared/rce/RceCommandShim'
  '../TreeBrowserView'
  '../RootFoldersFinder'
  '../FindFlickrImageView'
], (I18n, $, _, h, preventDefault, DialogBaseView, template, RceCommandShim, TreeBrowserView, RootFoldersFinder, FindFlickrImageView) ->

  class InsertUpdateImageView extends DialogBaseView

    template: template

    events:
      'change [name="image[width]"]' : 'constrainProportions'
      'change [name="image[height]"]' : 'constrainProportions'
      'click .flickrImageResult, .treeFile' : 'onFileLinkClick'
      'change [name="image[src]"]' : 'onImageUrlChange'
      'tabsshow .imageSourceTabs': 'onTabsshow'
      'dblclick .flickrImageResult, .treeFile' : 'onFileLinkDblclick'
      'change [name="image[data-decorative]"]': 'onDecorativeChange'

    dialogOptions:
      width: 625
      title: I18n.t 'titles.insert_edit_image', 'Insert / Edit Image'
      destroy: true

    toJSON: () ->
      {show_quiz_warning: ENV.SHOW_QUIZ_ALT_TEXT_WARNING}

    initialize: (@editor, selectedNode) ->
      @$editor = $("##{@editor.id}")
      @prevSelection = @editor.selection.getBookmark()
      @$selectedNode = $(selectedNode)
      super
      @render()
      @show()
      @dialog.parent().find('.ui-dialog-titlebar-close').click =>
        @restoreCaret()

      if @$selectedNode.prop('nodeName') is 'IMG'
        @setSelectedImage
          src: @$selectedNode.attr('src')
          alt: @$selectedNode.attr('alt')
          width: @$selectedNode.width()
          height: @$selectedNode.height()
          'data-decorative': @$selectedNode.attr('data-decorative')

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
            rootFoldersFinder = new RootFoldersFinder({
              contentTypes: 'image',
              useVerifiers: true
            })
            new TreeBrowserView(rootModelsFinder: rootFoldersFinder).render().$el.appendTo(ui.panel)
            done()
        when 'tabFlickr'
          loadTab (done) =>
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
        for key, value of newAttributes
          if (@$("[name='image[#{key}]']")).attr('type') == 'checkbox'
            @$("[name='image[#{key}]']").attr('checked', !!value)
          else
            @$("[name='image[#{key}]']").val(value)
        if newAttributes['data-decorative']
          @$("[name='image[alt]']").attr('disabled', true)
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
      if @$("[name='image[data-decorative]']").is(':checked')
        res['alt'] = ''
        res['data-decorative'] = true
      res['data-mce-src'] = res.src
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
      @$("[name='image[alt]']").focus()

    onFileLinkDblclick: (event) =>
      # click event is handled on the first click
      @update()

    onImageUrlChange: (event) ->
      @flickr_link = null
      @setSelectedImage src: $(event.currentTarget).val()

    onDecorativeChange: (event) ->
      if @$("[name='image[data-decorative]']").is(':checked')
        @$("[name='image[alt]']").attr('disabled', true)
      else
        @$("[name='image[alt]']").removeAttr('disabled')

    close: ->
      super
      @restoreCaret()

    restoreCaret: ->
      @editor.selection.moveToBookmark(@prevSelection)

    generateImageHtml: ->
      imgHtml = @editor.dom.createHTML("img", @getAttributes())
      if @flickr_link
        imgHtml = "<a href='#{h @flickr_link}'>#{imgHtml}</a>"
      imgHtml

    update: =>
      @restoreCaret()
      if @$selectedNode.is('img')
        # Kill the alt/decorative props (but they get added back if needed)
        @$selectedNode.removeAttr('alt')
        @$selectedNode.removeAttr('data-decorative')
        @$selectedNode.attr(@getAttributes())
      else
        RceCommandShim.send(@$editor, 'insert_code', @generateImageHtml())
      @editor.focus()
      @close()
