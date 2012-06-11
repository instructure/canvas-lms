define [
  'use!vendor/backbone'
  'underscore'
], (Backbone, _) ->

  Backbone.syncWithoutMultipart = Backbone.sync
  Backbone.syncWithMultipart = (method, model, options) ->
    # Create a hidden iframe
    iframeId = 'file_upload_iframe_' + (new Date()).getTime()
    $iframe = $("<iframe id='#{iframeId}' name='#{iframeId}' ></iframe>").hide()

    # Create a hidden form
    httpMethod = {create: 'POST', update: 'PUT', delete: 'DELETE', read: 'GET'}[method]
    toForm = (object, nested) ->
      inputs = _.map object, (attr, key) ->
        if _.isElement(attr)
          # leave a copy in the original form, since we're moving it
          $orig = $(attr)
          $orig.after($orig.clone(true))
          attr
        else if not _.isEmpty(attr) and (_.isArray(attr) or typeof attr is 'object')
          toForm(attr, key)
        else if not "#{key}".match(/^_/) and attr? and typeof attr isnt 'object' and typeof attr isnt 'function'
          $el = $ "<input/>",
            name: key
            value: attr
          $el[0]
      _.flatten(inputs)
    $form = $("""
      <form enctype='multipart/form-data' target='#{iframeId}' action='#{options.url ? model.url()}' method='POST'>
        <input type='hidden' name='_method' value='#{httpMethod}' />
        <input type='hidden' name='authenticity_token' value='#{ENV.AUTHENTICITY_TOKEN}' />
      </form>
    """).hide()
    $form.prepend(el for el in toForm(model) when el)

    $(document.body).prepend($iframe, $form)

    callback = ->
      # contentDocument doesn't work in IE (7)
      iframeBody = ($iframe[0].contentDocument || $iframe[0].contentWindow.document).body
      response = $.parseJSON($(iframeBody).text())

      # TODO: Migrate to api v2. Make this check redundant
      response = response.objects ? response

      if iframeBody.className is "error"
        options.error?(response)
      else
        options.success?(response)

      $iframe.remove()
      $form.remove()

    # Set up the iframe callback for IE (7)
    $iframe[0].onreadystatechange = ->
      callback() if @readyState is 'complete'

    # non-IE
    $iframe[0].onload = callback

    $form[0].submit()

  Backbone.sync = (method, model, options) ->
    if options?.multipart
      Backbone.syncWithMultipart.apply this, arguments
    else
      Backbone.syncWithoutMultipart.apply this, arguments
