# actually depends on tinymce already being on the page, but not required here
# to not disrupt the balance of requiring tinymce asynchronously

define ->

  markScriptLoaded = (urls) ->
    for url in urls
      id = tinymce.baseURI.toAbsolute(url) + '.js'
      tinymce.ScriptLoader.markDone id

