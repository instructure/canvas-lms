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

    render: ()->
      title_text = I18n.t('view_in_separate_window', "View in Separate Window")

      @$el.html @template({tree: @model, title_text: title_text})

      @$el.instTree
        autoclose: false,
        multi: false,
        dragdrop: false

    activateFile: (event)=>
      return if @$(event.target).closest(".popout").length > 0
      $target = @$(event.currentTarget)
      event.preventDefault()
      event.stopPropagation()
      @$(".file.active").removeClass 'active'
      $target.addClass 'active'
      file_id = $target.attr('id').substring(9)
      @trigger('activate-file', file_id)
      $("#submit_google_doc_form .btn-primary").focus()

    activateFolder: (event)=>
      $target = @$(event.target)
      if $target.closest('.sign').length == 0 && $target.closest('.file,.folder').hasClass('folder')
        @$(event.currentTarget).find(".sign").click()
        @$(event.currentTarget).find(".file").focus()

    tagName: 'ul'

    id: 'google_docs_tree'

    attributes:
      style: 'width: 100%;'
