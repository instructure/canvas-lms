define [
  'jquery'
  'compiled/jquery.kylemenu'
], ($, KyleMenu) ->

  # this is a behaviour that will automatically set up a set of .admin-links
  # when the button is clicked, see _admin_links.scss for markup
  $(document).on 'mousedown mouseup click keydown', '.al-trigger', (event) ->
    $trigger = $(this)
    return if $trigger.data('kyleMenu')
    opts = $.extend {noButton: true}, $trigger.data('kyleMenuOptions')
    opts.appendMenuTo = 'body' if $trigger.data('append-to-body')
    opts = $.extend opts,
      popupOpts:
        position:
          my: $trigger.data('popup-my')
          at: $trigger.data('popup-at')
          within: $trigger.data('popup-within')
    new KyleMenu($trigger, opts)

    $trigger.trigger(event)
