define [
  'ember'
  '../../shared/components/ic_lazy_list_component'
  '../../shared/components/form_dialog_component'
], (Ember, ICLazyList, FormDialogComponent) ->

  Ember.onLoad 'Ember.Application', (Application) ->
    Application.initializer
      name: 'SharedComponents'
      initialize: (container, application) ->
        container.register 'component:form-dialog', FormDialogComponent
        container.register 'component:ic-lazy-list', ICLazyList

  Ember.Application.extend

    rootElement: '#content'

