# Firefox doesn't clamp values for the number input. See: https://bugzilla.mozilla.org/1028712
# Should be removed once firefox fixes the issue and is used in production version of firefox.
define [
  'jquery'
  'jquery.instructure_forms'
  'i18n!firefox_fix'
], ($) ->

  onChangeHandler = (e) ->
    numInput = $(e.target)
    min = parseInt(numInput.attr("min"))
    throw "'min' attribute needs to be a number" if isNaN(min)
    current = parseInt(numInput.val())
    if !isNaN(current) and current < min  ## If current is a number and current < min
      numInput.val(min)
      #So the user's not wondering why their stuff got reset.
      #Will quickly flash on firefox when coming from a blank input.
      numInput.errorBox I18n.t("You must set it to a number greater than or equal to %{min}", { min: numInput.prop("min") })

  $.fn.activate_firefox_fix = () ->
    this.on 'change', 'input[type=number][min]', onChangeHandler

  $(document).activate_firefox_fix()
