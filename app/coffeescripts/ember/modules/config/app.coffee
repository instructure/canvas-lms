define [
  'ember'
  'ic-lazy-list'
  'ic-sortable'
  '../../shared/components/ic_actions_component'
  '../../shared/components/c_modal_form_component'
  '../../shared/components/c_datepicker_component'
  '../../shared/components/c_icon_component'
  '../../shared/components/fast_select_component'
  '../../shared/components/c_file_input_component'
], (Ember) ->

  Ember.TextSupport.reopen
    attributeBindings: [
      'aria-label'
      'autofocus'
    ]

  App = Ember.Application.extend
    rootElement: '#content'
    Router: Ember.Router.extend(location: 'none')
    #LOG_ACTIVE_GENERATION: true
    #LOG_VIEW_LOOKUPS: true

