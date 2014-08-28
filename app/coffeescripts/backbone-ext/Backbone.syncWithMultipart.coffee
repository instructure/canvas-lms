# copied from: https://gist.github.com/1998897

define [
  'vendor/backbone'
  'underscore'
  'jquery'
], (Backbone, _, $) ->

  Backbone.syncWithoutMultipart = Backbone.sync
  Backbone.syncWithMultipart = (method, model, options) ->
    # Create a hidden iframe
    iframeId = _.uniqueId 'file_upload_iframe_'
    $iframe = $("<iframe id='#{iframeId}' name='#{iframeId}' ></iframe>").hide()
    dfd = new $.Deferred()

    # Create a hidden form
    httpMethod = {create: 'POST', update: 'PUT', delete: 'DELETE', read: 'GET'}[method]
    toForm = (object, nested, asArray) ->
      inputs = _.map object, (attr, key) ->

        key = "#{nested}[#{if asArray then '' else key}]" if nested

        if _.isElement(attr)
          # leave a copy in the original form, since we're moving it
          $orig = $(attr)
          $orig.after($orig.clone(true))
          attr
        else if !_.isEmpty(attr) and (_.isArray(attr) or typeof attr is 'object')
          toForm(attr, key, _.isArray(attr))
        else if !"#{key}".match(/^_/) and attr? and typeof attr isnt 'object' and typeof attr isnt 'function'
          $el = $ "<input/>",
            name: key
            value: attr
          $el[0]
      _.flatten(inputs)
    $form = $("""
      <form enctype='multipart/form-data' target='#{iframeId}' action='#{options.url ? model.url()}' method='POST'>
      </form>
    """).hide()

    # pass proxyAttachment if the upload is being proxied through canvas (deprecated)
    if options.proxyAttachment
      $form.prepend """
        <input type='hidden' name='_method' value='#{httpMethod}' />
        <input type='hidden' name='authenticity_token' value='#{ENV.AUTHENTICITY_TOKEN}' />
        """

    _.each toForm(model.toJSON()), (el) ->
      return unless el
      if el.name is 'file' # s3 expects the file param last
        $form.append(el)
      else
        $form.prepend(el)

    $(document.body).prepend($iframe, $form)

    callback = ->
      # contentDocument doesn't work in IE (7)
      iframeBody = ($iframe[0].contentDocument || $iframe[0].contentWindow?.document)?.body
      response = $.parseJSON($(iframeBody).text())
      # in case the form redirects after receiving the upload (API uploads),
      # prevent trying to work with an empty response
      return unless response

      # TODO: Migrate to api v2. Make this check redundant
      response = response.objects ? response

      if iframeBody.className is "error"
        options.error?(response)
        dfd.reject(response)
      else
        options.success?(response)
        dfd.resolve(response)

      $iframe.remove()
      $form.remove()

    # Set up the iframe callback for IE (7)
    $iframe[0].onreadystatechange = ->
      callback() if @readyState is 'complete'

    # non-IE
    $iframe[0].onload = callback

    $form[0].submit()
    dfd

  Backbone.sync = (method, model, options) ->
    if options?.multipart
      Backbone.syncWithMultipart.apply this, arguments
    else
      Backbone.syncWithoutMultipart.apply this, arguments
