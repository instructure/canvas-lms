#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/views/tinymce/EquationEditorView'
], ($, EquationEditorView) ->

  QUnit.module "EquationEditorView#getEquationText",
    setup: ->
    teardown: ->

  test "just uses the text if it isn't really an element", ->
    equation = "65 * 32"
    elem  = $("<span>")
    elem.text(equation)
    equal(EquationEditorView.getEquationText(elem), "65 * 32")

  test "it extracts the data-equation-content attribute from an image if thats in the span", ->
    equation = "<img class=\"equation_image\" title=\"52\\ast\\sqrt{64}\" src=\"/equation_images/52%255Cast%255Csqrt%257B64%257D\" data-equation-content=\"52\\ast\\sqrt{64}\" alt=\"52\\ast\\sqrt{65}\"/>"
    elem  = $("<span>")
    elem.text(equation)
    equal(EquationEditorView.getEquationText(elem), "52\\ast\\sqrt{64}")

  test "it extracts the alt from an image if there is no data-equation-content in the span", ->
    equation = "<img class=\"equation_image\" title=\"52\\ast\\sqrt{64}\" src=\"/equation_images/52%255Cast%255Csqrt%257B64%257D\" alt=\"52\\ast\\sqrt{64}\" />"
    elem  = $("<span>")
    elem.text(equation)
    equal(EquationEditorView.getEquationText(elem), "52\\ast\\sqrt{64}")

  QUnit.module "EquationEditorView#render",
    setup: ->
    teardown: ->
      $('.ui-dialog').remove()

  test "it renders into a div (because spans break KO nav)", ->
    editor = {
      selection: {
        getBookmark: (()-> return null),
        getNode: (()-> return "Node Text"),
        getContent: (()-> return "Editor Content")
      }
    }
    view = new EquationEditorView(editor)
    equal(view.el.nodeName, "DIV")
