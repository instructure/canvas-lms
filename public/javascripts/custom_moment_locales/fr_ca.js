require('moment/locale/fr-ca')
const moment = require('moment')

const data = moment.localeData('fr-ca')

data._monthsShort = [
  'Jan',
  'Fév',
  'Mar',
  'Avr',
  'Mai',
  'Jun',
  'Jul',
  'Aou',
  'Sep',
  'Oct',
  'Nov',
  'Déc'
]
