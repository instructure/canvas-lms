# Creates a 'settings' pop up menu using ic-menu
#
# include ic-actions in your config/app.coffee
# set a title property for screen-readers
# give the block a set of ic-menu-items
#
# {{#ic-actions title='settings'}}
#  {{#ic-menu-item on-select='edit'}}Edit{{/ic-menu-item}}
#  {{#ic-menu-item on-select='delete'}}Delete{{/ic-menu-item}}
#{{/ic-actions}}
#
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

