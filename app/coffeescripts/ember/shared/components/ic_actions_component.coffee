define [
  'ember'
  '../register'
  'i18n!ic_actions'
  'ic-menu'
  '../templates/components/ic-actions'
  '../templates/components/ic-actions-css'
], (Ember, register, I18n) ->

  register 'component', 'ic-actions', Ember.Component.extend

    tagName: 'ic-actions'

    title: I18n.t('manage', 'manage')

