define [
  'ember'
  'timezone'
  '../register'
  'jquery.instructure_date_and_time'
  '../templates/components/c-datepicker'
], (Ember, tz, register) ->

  Ember.TextSupport.reopen
    attributeBindings: ['style']

  register 'component', 'c-datepicker', Ember.Component.extend

    value: ((key, val) ->
      input = @get('input')
      if input
        tz.format(tz.parse(input.data('date')), '%b %e, %Y %l:%M %P')
      else
        val
    ).property('input')

    createLegacyPicker: (->
      input = this.$('input')
      @set('input', input)
      input.datetime_field()
    ).on('didInsertElement')

