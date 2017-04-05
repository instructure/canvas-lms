import $ from 'jquery'
import deparam from 'compiled/util/deparam'

$(document).ready(() => {
  const params = deparam()
  if (params.focus) {
    const el = $(`#${params.focus}`)
    if (el) {
      if (el.attr('type') === 'text') { el.select() }
      el.focus()
    }
  }
})
