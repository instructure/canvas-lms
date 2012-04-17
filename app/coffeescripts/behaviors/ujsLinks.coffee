# copied from
# https://github.com/rails/jquery-ujs

define ['jquery'], ($) ->

  ##
  # Handles "data-method" on links such as:
  # <a href="/users/5" data-method="delete" rel="nofollow" data-confirm="Are you sure?">Delete</a>
  handleMethod = (link) ->
    link.data 'handled', true
    href = link.attr('href')
    method = link.data('method')
    target = link.attr('target')
    form = $("<form method='post' action='#{href}'></form>")
    metadataInput = "<input name='_method' value='#{method }' type='hidden' />"

    if ENV.AUTHENTICITY_TOKEN
      metadataInput += "<input name='authenticity_token' value='#{ENV.AUTHENTICITY_TOKEN}' type='hidden' />"

    form.attr('target', target) if target
    form.hide().append(metadataInput).appendTo('body').submit()


  # For 'data-confirm' attribute:
  #  - Shows the confirmation dialog
  allowAction = (element) ->
    message = element.data('confirm')
    return true unless message

    confirm(message)

  $(document).delegate 'a[data-confirm], a[data-method]', 'click', (event) ->
    $link = $(this)

    return false if $link.data 'handled'
    return false unless allowAction($link)

    if $link.data('method')
      handleMethod($link)
      return false

