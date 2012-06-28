define [
  'jquery'
  'compiled/jquery.kylemenu'
], ($, KyleMenu) ->

  # this is a behaviour that will automatically set up a set of .admin-links
  # when the button is clicked, see _admin_links.scss for markup
  $(document).on 'click', '.al-trigger', (event) ->
    $trigger = $(this)
    defaults =
      buttonOpts:
        icons:
          primary: null
          secondary: null

    unless $trigger.data('kyleMenu')
      event.preventDefault()
      opts = $.extend defaults, $trigger.data('kyleMenuOptions')
      new KyleMenu($trigger, opts).open()
