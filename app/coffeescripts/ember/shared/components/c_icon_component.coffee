define [
  'ember'
  '../register'
  '../templates/components/c-icon'
], (Ember, register) ->

  register 'component', 'c-icon', Ember.Component.extend

    tagName: 'i'

    classNameBindings: ['iconClass']

    iconClass: (->
      "icon-#{@get('type')}"
    ).property('type')

