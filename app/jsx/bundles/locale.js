import $ from 'jquery'
import Popover from 'compiled/util/Popover'

$(() => {
  const $select = $('select.locale')

  const $warningLink = $('i.locale-warning')
  $warningLink.hide()

  function checkWarningIcon () {
    if (Array.from(ENV.crowdsourced_locales).includes($select.val())) {
      $warningLink.show()
    } else {
      $warningLink.hide()
    }
  }

  $select.change(() => checkWarningIcon())

  return checkWarningIcon()
})

