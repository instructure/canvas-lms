define [
  'ember'
  '../../shared/components/form_dialog_component'
  'ic-lazy-list'
], (Ember, FormDialogComponent) ->

  Ember.onLoad 'Ember.Application', (Application) ->
    Application.initializer
      name: 'SharedComponents'
      initialize: (container, application) ->
        container.register 'component:form-dialog', FormDialogComponent

  Ember.Application.extend

    rootElement: '#content'

