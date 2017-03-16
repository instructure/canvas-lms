define [
  'ember',
  'i18nObj'
  'jsx/shared/helpers/numberFormat'
], (Ember, I18n, numberFormat) ->
  Ember.Handlebars.registerBoundHelper 'n', (number, options) ->
    I18n.n(number, options.hash)

  Ember.Handlebars.registerBoundHelper 'nf', (number, options) ->
    numberFormat[options.hash.format](number)
