/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import $ from 'jquery'
import EquationEditorView from 'compiled/views/tinymce/EquationEditorView'

QUnit.module('EquationEditorView', () => {
  QUnit.module('doubleEncodeEquationForUrl', () => {
    test('encodes pound sign using utf-8', assert => {
      const equation = '\xA3'
      assert.equal(EquationEditorView.doubleEncodeEquationForUrl(equation), '%25C2%25A3')
    })
  })

  QUnit.module('getEquationText', () => {
    test("just uses the text if it isn't really an element", assert => {
      const equation = '65 * 32'
      const elem = $('<span>')
      elem.text(equation)
      assert.equal(EquationEditorView.getEquationText(elem), '65 * 32')
    })
    test('it extracts the data-equation-content attribute from an image if thats in the span', assert => {
      const equation =
        '<img class="equation_image" title="52\\ast\\sqrt{64}" src="/equation_images/52%255Cast%255Csqrt%257B64%257D" data-equation-content="52\\ast\\sqrt{64}" alt="52\\ast\\sqrt{65}"/>'
      const elem = $('<span>')
      elem.text(equation)
      assert.equal(EquationEditorView.getEquationText(elem), '52\\ast\\sqrt{64}')
    })
    test('it extracts the alt from an image if there is no data-equation-content in the span', assert => {
      const equation =
        '<img class="equation_image" title="52\\ast\\sqrt{64}" src="/equation_images/52%255Cast%255Csqrt%257B64%257D" alt="52\\ast\\sqrt{64}" />'
      const elem = $('<span>')
      elem.text(equation)
      assert.equal(EquationEditorView.getEquationText(elem), '52\\ast\\sqrt{64}')
    })
    test('it strips MathJAx block delimiters">', assert => {
      const equation = '$$y = sqrt{x}$$'
      const elem = $('<span>')
      elem.text(equation)
      assert.equal(EquationEditorView.getEquationText(elem), 'y = sqrt{x}')
    })
    test('it strips MathJAx inline delimiters">', assert => {
      const equation = '\\(y = sqrt{x}\\)'
      const elem = $('<span>')
      elem.text(equation)
      assert.equal(EquationEditorView.getEquationText(elem), 'y = sqrt{x}')
    })
  })

  QUnit.module('render', hooks => {
    hooks.afterEach(() => {
      document.querySelector('.ui-dialog').remove()
    })
    test('it renders into a div (because spans break KO nav)', assert => {
      const editor = {
        selection: {
          getBookmark() {
            return null
          },
          getNode() {
            return 'Node Text'
          },
          getContent() {
            return 'Editor Content.'
          },
          moveToBookmark() {}
        }
      }
      const view = new EquationEditorView(editor)
      assert.equal(view.el.nodeName, 'DIV')
    })
  })
})
