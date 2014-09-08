define [
  '../register'
  'ember'
  'ic-modal'
  'i18n!c_modal_form'
  '../templates/components/c-modal-form'
], (register, Ember, Modal, I18n) ->

  {ModalFormComponent, ModalComponent, modalCss} = Modal


  ModalComponent.reopen
    attributeBindings: ['id']
    toggleBodyClassOnClose: (->
      $(document.body).addClass('ic-modal-open')
    ).on('willOpen')
    toggleBodyClassOnOpen: (->
      $(document.body).removeClass('ic-modal-open')
    ).on('willClose')

  Ember.Application.initializer
    name: 'c-modal-form-component'
    after: 'ic-modal'
    initialize: (container) ->
      container.register('template:components/c-modal-form-css', modalCss)


  register 'component', 'c-modal-form', ModalFormComponent.extend

    attributesBindings: [
      # provides a declarative way to return focus to an element by id after
      # the form is closed
      'return-focus-to'
    ]

    classNames: ['form-horizontal', 'bootstrap-form']

    closeText: I18n.t('close', 'close')

    maybeMakeDefaultChildren: ->
      @_super.apply this, arguments
      throw new Error('you must add an {{ic-modal-title}}') if @get('makeTitle')

    close: ->
      # TODO: consider this for ic-modal upstream?
      @_super.apply(this, arguments)
      returnFocusTo = @get('return-focus-to')
      if returnFocusTo
        # go for an ember view first since components may have focus methods
        # that do the right thing™
        target = Ember.View.views[returnFocusTo]
        target ?= document.getElementById("##{returnFocusTo}")
        target.focus()

