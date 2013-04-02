define [
  'jquery'
  'compiled/jquery.kylemenu'
], ($, KyleMenu) ->

  # this is a behaviour that will automatically set up a set of .admin-links
  # when the button is clicked, see _admin_links.scss for markup
  $(document).on 'click keydown', '.al-trigger', (event) ->
    $trigger = $(this)
    return $trigger.click() if event.keyCode

    unless $trigger.data('kyleMenu')
      event.preventDefault()
      opts = $.extend {noButton: true}, $trigger.data('kyleMenuOptions')
      new KyleMenu($trigger, opts).open()
