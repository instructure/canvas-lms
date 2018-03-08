module.exports = {
  // eslint-disable-line import/no-commonjs
  name: 'fr_CA',
  day: {
    abbrev: ['dim', 'lun', 'mar', 'mer', 'jeu', 'ven', 'sam'],
    full: ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi']
  },
  month: {
    abbrev: ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aou', 'Sep', 'Oct', 'Nov', 'Déc'],
    full: [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ]
  },
  meridiem: ['', ''],
  date: '%Y-%m-%d',
  time24: '%T',
  dateTime: '%a %d %b %Y %T %Z',
  time12: '',
  full: '%A %-e %B %Y, %H:%M:%S (UTC%z)'
}
