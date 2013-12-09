require [
  'i18n!chat'
  'jquery',
], (I18n, $) ->

  tinychat =
    room    : ENV.tinychat.room
    nick    : ENV.tinychat.nick
    colorbk : '0xffffff'
    oper    : 'none'
    owner   : 'none'
    change  : 'none'
    join    : 'auto'
    api     : 'none'
    key     : ENV.tinychat.key

  embedTinychat = (params, options) ->
    data = []
    data.push("#{i}=#{encodeURIComponent(params[i])}") for i of params

    queryString = data.join('&')

    frame     = document.createElement('iframe')
    context   = ENV.context_asset_string.split('_')
    frame.src = "tinychat.html?#{queryString}"

    frame.style.width  = '100%'
    frame.style.height = '100%'
    frame.style.border = 0
    frame.frameBorder  = 0

    container              = document.createElement('div')
    container.className    = 'tinychat_embed'
    container.style.height = '720px'
    container.appendChild(frame)

    options        ?= {}
    options.height ?= '700px'
    options.width  ?= '600px'

    div = document.createElement('div')
    div.appendChild(container)

    element = document.getElementById('client')
    if !element
      document.write(div.innerHTML)
    else
      element.innerHTML = div.innerHTML

    if container.style.width is ''
      container.style.width = options.width

    if container.style.height is ''
      container.style.height = options.height

    return frame

  $(document).ready ->
    embedTinychat(tinychat) unless typeof tinychat is 'undefined'
    $.screenReaderFlashMessage(I18n.t('notifications.tinychat_inaccessible',
      'Warning: This page uses  Tinychat, a third party plugin that is not
      accessible to screen readers.'))
