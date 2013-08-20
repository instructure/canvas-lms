define [
  'i18n!assignments'
  'Backbone'
  'underscore'
  'compiled/views/PublishIconView'
  'compiled/views/VddTooltipView'
  'compiled/views/assignments/CreateAssignmentView'
  'jst/assignments/AssignmentListItem'
], (I18n, Backbone, _, PublishIconView, VddTooltipView, CreateAssignmentView, template) ->

  class AssignmentListItemView extends Backbone.View
    tagName: "li"
    template: template

    @child 'publishIconView',    '[data-view=publish-icon]'
    @child 'vddDueTooltipView',  '[data-view=vdd-due-tooltip]'
    @child 'editAssignmentView', '[data-view=editAssignment]'

    els:
      '.edit_assignment': '$editAssignmentButton'

    events:
      'click .delete_assignment': 'onDelete'

    messages:
      confirm: I18n.t('confirms.delete_assignment', 'Are you sure you want to delete this assignment?')

    initialize: ->
      super
      @initializeChildViews()

      if @canManage()
        @model.on('change:published', @updatePublishState)

        # re-render for attributes we are showing
        attrs = ["name", "points_possible", "due_at", "lock_at", "unlock_at"]
        observe = _.map(attrs, (attr) -> "change:#{attr}").join(" ")
        @model.on(observe, @render)

    initializeChildViews: ->
      @publishIconView = false
      @editAssignmentView = false
      @vddDueTooltipView = false

      if @canManage()
        @publishIconView    = new PublishIconView(model: @model)
        @editAssignmentView = new CreateAssignmentView(model: @model)

        if @model.multipleDueDates()
          @vddDueTooltipView = new VddTooltipView(model: @model)

    upatePublishState: =>
      @$('.ig-row').toggleClass('ig-published', @model.get('published'))

    # call remove on children so that they can clean up old dialogs.
    render: ->
      @publishIconView.remove() if @publishIconView
      @editAssignmentView.remove() if @editAssignmentView
      @vddDueTooltipView.remove() if @vddDueTooltipView
      super

    afterRender: ->
      @createModuleToolTip()

      if @editAssignmentView
        @editAssignmentView.hide()
        @editAssignmentView.setTrigger @$editAssignmentButton

    createModuleToolTip: =>
      link = @$el.find('.tooltip_link')
      link.tooltip
        position:
          my: 'center bottom'
          at: 'center top-10'
          collision: 'fit fit'
        tooltipClass: 'center bottom vertical'
        content: ->
          $(link.data('tooltipSelector')).html()

    toJSON: ->
      data = @model.toView()
      data.canManage = @canManage()

      if modules = @modules(data.id)
        moduleName = modules[0]
        has_modules = modules.length > 0
        joinedNames = modules.join(",")
        _.extend data, {
          modules: modules
          module_count: modules.length
          module_name: moduleName
          has_modules: has_modules
          joined_names: joinedNames
        }
      else
        data

    onDelete: (e) =>
      e.preventDefault()
      @delete() if confirm(@messages.confirm)

    delete: ->
      @model.destroy()
      @$el.remove()

    modules: (id) ->
      ENV.MODULES[id]

    canManage: ->
      ENV.PERMISSIONS.manage
