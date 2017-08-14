require('moment/locale/fr')
const moment = require('moment')

const data = moment.localeData('fr')

data._monthsShort = [
  'Jan',
  'Fév',
  'Mar',
  'Avr',
  'Mai',
  'Jun',
  'Juil',
  'Aou',
  'Sep',
  'Oct',
  'Nov',
  'Déc'
]
