require [
  'jquery'
  'compiled/util/Popover'
], ($, Popover) ->
  $ ->
    $select = $('select.locale')

    $warningLink = $('i.locale-warning')
    $warningLink.hide()

    checkWarningIcon = ->
      if $select.val() in ENV.crowdsourced_locales
        $warningLink.show()
      else
        $warningLink.hide()

    $select.change ->
      checkWarningIcon()

    checkWarningIcon()
