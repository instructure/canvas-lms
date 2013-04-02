define [
  'i18n!editor'
  'jquery'
  'Backbone'
  'jst/tinymce/EquationToolbarView'
  'mathquill'
], (I18n, $, Backbone, template) ->

  class EquationToolbarView extends Backbone.View

    template: template

    els:
      '#mathjax-view .mathquill-toolbar': '$toolbar'
      '#mathjax-editor': '$matheditor'

    render: ->
      @cacheEls()
      @$toolbar.append(@template())

      $('#mathjax-view .mathquill-tab-bar li a').click( ->
        $('#mathjax-view .mathquill-tab-bar li').removeClass('mathquill-tab-selected')
        $('#mathjax-view .mathquill-tab-pane').removeClass('mathquill-tab-pane-selected')
        $(this).parent().addClass('mathquill-tab-selected')
        $(this.href.replace(/.*#/, '#')).addClass('mathquill-tab-pane-selected')
      )
      $('#mathjax-view .mathquill-tab-bar li:first-child').addClass('mathquill-tab-selected')

      $.getScript("https://c328740.ssl.cf1.rackcdn.com/mathjax/2.1-latest/MathJax.js?config=TeX-AMS_HTML.js", @addMathJaxEvents)

    addMathJaxEvents: =>
      renderPreview = ->
        jax = MathJax.Hub.getAllJax("mathjax-preview")[0];
        if jax
          tex = $('#mathjax-editor').val()
          MathJax.Hub.Queue(["Text", jax, tex])

      $('#mathjax-view a.mathquill-rendered-math').mousedown( (e) ->
        e.stopPropagation()
      ).click( ->
        text = this.title + ' '
        field = document.getElementById('mathjax-editor')
        if document.selection
          field.focus()
          sel = document.selection.createRange()
          sel.text = text
        else if field.selectionStart || field.selectionStart == '0'
          s = field.selectionStart
          e = field.selectionEnd
          val = field.value
          field.value = val.substring(0, s) + text + val.substring(e, val.length)
        else
          field.value += text

        renderPreview()
      )

      @renderPreview = renderPreview
      @$matheditor.keyup(renderPreview)
      @$matheditor.bind('paste', renderPreview)

