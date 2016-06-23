define [
  'jquery'
  'jsx/shared/rce/RceCommandShim'
], ($, RceCommandShim) ->

  $fixtures = $('#fixtures')

  return {
    setup: (innerHTML='') ->
      $fixtures.innerHTML = innerHTML

    create: (source) ->
      $fixture = $(source)
      $fixtures.append($fixture)
      return $fixture

    find: (selector) ->
      return $(selector, $fixtures)

    teardown: () ->
      # detach any legacy editorBox stuff before removing
      this.find('textarea').each (i, el) ->
        $editor = $(el)
        if ($editor.data('rich_text'))
          RceCommandShim.send($editor, 'destroy')

      $fixtures.empty()
  }
