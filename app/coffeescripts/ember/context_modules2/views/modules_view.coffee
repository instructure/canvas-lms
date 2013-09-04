define [
  'ember'
  'jquery'
  'underscore'
  '../models/module'
  # 'vendor/jqueryui/sortable'
], (Ember,$,_,Module) ->
  fixHelper = (e, ui) ->
    ui.children().each ->
      $(this).width $(this).width()
    ui

  IndexView = Ember.View.extend
    didInsertElement: ->
      $(window).scroll =>
        if $(window).scrollTop() + $(window).height() >= $(document).height() - 300
          Module.loadNextPage()

      # Set up sorting for modules. Temporarily disabled
      if false
        @sortableModules = @$(".sortable-modules").sortable(
          axis: "y"
          connectWith: ".sortable-modules"
          items: "> div.module"
          helper: fixHelper
        ).disableSelection()
        oldParentId = undefined
      
      # Set up sorting for module items (within modules and across modules)
      
      # console.log('# of module items',ui.item.parents('.module').find('.module-item[data-module-item-id]').length);
      
      # debugger;
      # console.log('# of module parents',ui.item.parents('.module').length);
      # console.log('oldParentId',oldParentId);
      # var this.get('controller.model')[0].id
      
      #ui.item.data('id')
      
      # debugger;
      # http://stackoverflow.com/a/7340208
      
      # Accounting for <script> siblings
      
      # Ack! TODO: Use model
      # from 0-based to 1-based index
      if false
        @sortableModuleItems = @$(".sortable-module-items > tbody").sortable(
          axis: "y"
          connectWith: ".sortable-module-items > tbody"
          items: "> tr"
          helper: fixHelper
          change: (event, ui) ->
            return  unless ui.sender
            if $(ui.sender).find(".module-item[data-module-item-id]").length > 1
              $(ui.sender).removeClass "empty"
            else
              $(ui.sender).addClass "empty"

          deactivate: (event, ui) ->
            if $(event.target).find(".module-item[data-module-item-id]").length
              $(event.target).removeClass "empty"
            else
              $(event.target).addClass "empty"

          start: (event, ui) =>
            oldParentId = ui.item.parents(".module").data("module-id")

          update: (event, ui) ->
            return  if this isnt ui.item.parent()[0]
            module_id = ui.item.parents(".module").data("module-id")
            module_item_id = ui.item.data("module-item-id")
            index = ui.item.parent().find("> tr").index(ui.item)
            url = "/api/v1/courses/" + window.ENV.COURSE_ID + "/modules/" + module_id + "/items/" + module_item_id
            $.ajax
              url: url
              type: "PUT"
              data:
                module_item:
                  position: index + 1

              success: (result) ->

        ).disableSelection()
        @sortableInitialized = true

    observeAllTheThings: _.throttle(->
      return
      return  if @state isnt "inDOM"
      console.time "refresh"
      if false
        @sortableModules.sortable "refresh"
        @sortableModuleItems.sortable "refresh"
      console.timeEnd "refresh"
    , 150).observes("controller.@each.items.@each")
