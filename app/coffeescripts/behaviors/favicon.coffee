define ['jquery', 'INST'], ($, INST) ->
  link = null
  set = (env) ->
    link.remove() if link
    favicon = if env == 'development'
      '/favicon-green.ico'
    else if env == 'test'
      '/favicon-yellow.ico'
    else
      '/favicon.ico'
    link = $('<link />').attr(rel: 'icon', type: 'image/x-icon', href: favicon)
    $(document.head).append(link)
  set(INST?.environment)
  set
