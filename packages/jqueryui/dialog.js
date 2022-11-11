import $ from 'jquery'
import h from 'html-escape'
import './dialog-unpatched'

// Doing this because there's just one string to translate in this package and we don't want
// to create a whole new translation pipeline for one package. Additionally, we're eventually
// moving away from jqueryui, and the string 'Close' should always be present in the existing
// translation files. Find a better solution if we end up with more than just a single string
// to translate, or if the strings that need translation are more complex.
const parseCloseString = packageTranslations => packageTranslations?.close_d634289d?.message
import(`@instructure/translations/lib/${ENV.LOCALE}.json`)
  .then(packageTranslations => extendDialog(parseCloseString(packageTranslations)))
  .catch(() =>
    import(`@instructure/translations/lib/${ENV.LOCALE?.replace(/-/g, '_')}.json`)
      .then(packageTranslations => extendDialog(parseCloseString(packageTranslations)))
      .catch(() => extendDialog())
  )

const extendDialog = (translatedClose = 'close') => {
  // have UI dialogs default to modal:true
  $.ui.dialog.prototype.options.modal = true

  // based on d209434 and 83639ec, htmlEscape string titles by default, and
  // support jquery object titles
  function fixTitle(title) {
    if (!title) return title
    return title.jquery ? $('<div />').append(title.eq(0).clone()).html() : h('' + title)
  }

  const create = $.ui.dialog.prototype._create,
    setOption = $.ui.dialog.prototype._setOption

  $.extend($.ui.dialog.prototype, {
    _create() {
      if (!this.options.title) {
        this.options.title = this.element.attr('title')
        if (typeof this.options.title !== 'string') this.options.title = ''
      }
      this.options.title = fixTitle(this.options.title)
      this.options.closeText = translatedClose
      this._on({
        dialogopen() {
          $('#application').attr('aria-hidden', 'true')
        },
        dialogclose() {
          $('#application').attr('aria-hidden', 'false')
        },
      })
      return create.apply(this, arguments)
    },

    _setOption(key, value) {
      if (key == 'title') value = fixTitle(value)
      return setOption.call(this, key, value)
    },
  })
}
