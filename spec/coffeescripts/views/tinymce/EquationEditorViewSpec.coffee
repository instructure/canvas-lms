define [
  'jquery'
  'compiled/views/tinymce/EquationEditorView'
], ($, EquationEditorView) ->

  module "EquationEditorView#getEquationText",
    setup: ->
    teardown: ->

  test "just uses the text if it isn't really an element", ->
    equation = "65 * 32"
    elem  = $("<span>")
    elem.text(equation)
    equal(EquationEditorView.getEquationText(elem), "65 * 32")

  test "it extracts the alt from an image if thats in the span", ->
    equation = "<img class=\"equation_image\" title=\"52\\ast\\sqrt{64}\" src=\"/equation_images/52%255Cast%255Csqrt%257B64%257D\" alt=\"52\\ast\\sqrt{64}\" />"
    elem  = $("<span>")
    elem.text(equation)
    equal(EquationEditorView.getEquationText(elem), "52\\ast\\sqrt{64}")
