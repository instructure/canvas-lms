define [
  'ember'
  '../../shared/components/form_dialog_component'
  '../components/groups_lazy_list_component'
], (Ember, FormDialogComponent) ->

  Ember.onLoad 'Ember.Application', (Application) ->
    Application.initializer
      name: 'SharedComponents'
      initialize: (container, application) ->
        container.register 'component:form-dialog', FormDialogComponent

  Ember.Application.extend

    rootElement: '#content'

