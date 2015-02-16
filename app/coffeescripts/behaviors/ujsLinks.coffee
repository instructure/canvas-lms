# copied from
# https://github.com/rails/jquery-ujs

define ['jquery', 'compiled/behaviors/authenticity_token', 'str/htmlEscape'], ($, authenticity_token, htmlEscape) ->

  ##
  # Handles "data-method" on links such as:
  # <a data-url="/users/5" data-method="delete" rel="nofollow" data-confirm="Are you sure?">Delete</a>
  handleMethod = (link) ->
    link.data 'handled', true
    href = link.data('url') || link.attr('href')
    method = link.data('method')
    target = link.attr('target')
    form = $("<form method='post' action='#{htmlEscape href}'></form>")
    metadataInputHtml = "<input name='_method' value='#{htmlEscape method}' type='hidden' />"
    metadataInputHtml += "<input name='authenticity_token' type='hidden' />"

    form.attr('target', target) if target
    form.hide().append(metadataInputHtml).appendTo('body').submit()


  # For 'data-confirm' attribute:
  #  - Shows the confirmation dialog
  allowAction = (element) ->
    message = element.data('confirm')
    return true unless message

    confirm(message)

  $(document).delegate 'a[data-confirm], a[data-method], a[data-remove]', 'click', (event) ->
    $link = $(this)

    return false if $link.data('handled') || !allowAction($link)

    if $link.data('remove')
      handleRemove($link)
      return false

    else if $link.data('method')
      handleMethod($link)
      return false

  ##
  # for clicking link to remove element from page and send DELETE request to remove it from db
  # sample markup:
  # <div class="user">
  #   Clicking the × will make the .user div go away, if the ajax request fails it will reappear.
  #   <a class="close" href="#" data-url="/users/5" data-remove=".user" data-confirm="Are you sure?"> × </a>
  # </div>
  handleRemove = ($link) ->
    selector = $link.data('remove')
    $startLookingFrom = $link
    url = $link.data('url')

    # special case for handling links inside of a KyleMenu that were appendedTo the body and are
    # no longer children of where they should be
    closestKyleMenu = $link.closest(':ui-popup').popup('option', 'trigger').data('KyleMenu')
    if closestKyleMenu && closestKyleMenu.opts.appendMenuTo
      $startLookingFrom = closestKyleMenu.$placeholder

    $elToRemove = $startLookingFrom.closest(selector)

    # bind the 'beforeremove' and 'remove' events if you want to handle this with your own code
    # if you stop propigation this will not remove it
    $elToRemove.bind
      beforeremove: -> $elToRemove.hide()
      remove: -> $elToRemove.remove()

    $elToRemove.trigger 'beforeremove'

    triggerRemove = -> $elToRemove.trigger 'remove'
    revert = -> $elToRemove.show()

    if url
      $.ajaxJSON url, "DELETE", {}, triggerRemove, revert
    else
      triggerRemove()

