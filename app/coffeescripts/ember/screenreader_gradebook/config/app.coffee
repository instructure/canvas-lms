define [
  'ember',
  'compiled/handlebars_helpers',
  'handlebars/dist/cjs/handlebars'
], (Ember, HandlebarsRuntime, {default: Handlebars}) ->
  Handlebars.helpers = HandlebarsRuntime.helpers

  Ember.Application.extend

    rootElement: '#content'


