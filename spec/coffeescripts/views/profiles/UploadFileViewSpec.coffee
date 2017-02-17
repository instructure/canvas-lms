define [
  'compiled/views/profiles/UploadFileView'
  'compiled/util/BlobFactory'
], (UploadFileView, BlobFactory) ->

  QUnit.module 'UploadFileView',
    setup: ->
      @view  = new UploadFileView(avatarSize: { h: 128, w: 128 })
      @view.$el.appendTo('#fixtures')
      @file  = (->
        dfd    = $.Deferred()
        xhr  = new XMLHttpRequest()
        xhr.open('GET', '/base/spec/javascripts/fixtures/pug.jpg')
        xhr.responseType = 'blob'
        xhr.onload = (e) ->
          response = BlobFactory.fromXHR(@response, 'image/jpeg')
          dfd.resolve(response)
        xhr.send()
        dfd
      )()
      @view.render()

    teardown: ->
      delete @blob
      @view.remove()

  asyncTest 'loads given file', 3, ->
    # initial state
    ok @view.$el.find('.avatar-preview').length == 0, 'picker begins without preview image'

    $.when(@file).pipe(@view.loadPreview).done(=>
      # loaded state
      $preview  = @view.$('.avatar-preview')
      $fullsize = @view.$('img.Cropper-image')

      ok $preview.length > 0,                     'preview image exists'
      ok $fullsize.attr('src') != '',             'image loader contains loaded image after load'

      start()
    )

  asyncTest 'getImage returns cropped image object', 1, ->
    $.when(@file).pipe(@view.loadPreview).done(=>
      @view.getImage().then((image) ->
        ok image instanceof Blob, 'image object is a blob'
        start()
      )
    )
