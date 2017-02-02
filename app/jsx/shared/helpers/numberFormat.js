import I18n from 'i18nObj'

  const numberFormat = {
    _format (n, options) {
      if (typeof n !== 'number' || isNaN(n)) {
        return n
      }
      return I18n.n(n, options)
    },

    outcomeScore (n) {
      return numberFormat._format(n, {precision: 2, strip_insignificant_zeros: true})
    }
  }

export default numberFormat
