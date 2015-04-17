define [
  'i18n!titles'
  'jquery'
  'Backbone'
  'jst/googleDocsTreeView'
  'jquery.inst_tree'
], (I18n, $, Backbone, template)->

  class GoogleDocsTreeView extends Backbone.View

    template: template

    events:
      "click li.file": "activateFile",
      "click li.folder": "activateFolder",
      "keydown": "handleKeyboard",

    render: ()->
      title_text = I18n.t('view_in_separate_window', "View in Separate Window")

      @$el.html @template({tree: @model, title_text: title_text})

      @$el.instTree
        autoclose: false,
        multi: false,
        dragdrop: false

    handleKeyboard: (ev)=>
      if (ev.keyCode == 32) # When the spacebar is pressed
        if $(document.activeElement).hasClass("file")
          this.activateFile(ev)
        else if $(document.activeElement).hasClass("folder")
          this.activateFolder(ev)

    activateFile: (event)=>
      return if @$(event.target).closest(".popout").length > 0

      if event.type == "keydown" 
        $target = @$(event.target)
      else
        $target = @$(event.currentTarget)

      event.preventDefault()
      event.stopPropagation()
      @$(".file.active").removeClass 'active'
      $target.addClass 'active'
      file_id = $target.attr('id').substring(9)
      @trigger('activate-file', file_id)
      $("#submit_google_doc_form .btn-primary").focus()

    activateFolder: (event)=>
      if event.type == "keydown"
        event.preventDefault()
        $target = @$(event.target).find(".sign")
        folder  = @$(event.target)
      else
        $target = @$(event.target)
        if $target.closest('.sign').length == 0
          folder = @$(event.currentTarget)

      if folder && $target.closest('.file,.folder').hasClass('folder')
        folder.find(".sign").click()
        folder.find(".file").focus()

    tagName: 'ul'

    id: 'google_docs_tree'

    attributes:
      style: 'width: 100%;'
