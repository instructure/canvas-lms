/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

define(
  ['react', 'react-modal', 'jsx/theme_editor/ThemeEditorModal'],
  (React, Modal, ThemeEditorModal) => {
    let elem, props

    QUnit.module('ThemeEditorModal Component', {
      setup() {
        elem = document.createElement('div')
        props = {
          showProgressModal: false,
          showSubAccountProgress: false,
          progress: 0.5,
          activeSubAccountProgresses: []
        }
      }
    })

    test('modalOpen', () => {
      const c = new ThemeEditorModal(props)

      notOk(c.modalOpen(), 'modal is closed')

      c.props.showProgressModal = true
      ok(c.modalOpen(), 'modal is open')

      c.props.showProgressModal = false
      c.props.showSubAccountProgress = true
      ok(c.modalOpen(), 'modal is open')
    })

    test('modalContent', () => {
      const c = new ThemeEditorModal(props)
      const content = {name: 'content'}
      const subContent = {name: 'subContent'}
      sinon.stub(c, 'previewGenerationModalContent').returns(content)
      sinon.stub(c, 'subAccountModalContent').returns(subContent)

      equal(c.modalContent(), undefined, 'no modal content')

      c.props.showProgressModal = true
      equal(c.modalContent(), content, 'returns previewGenerationModalContent')

      c.props.showProgressModal = false
      c.props.showSubAccountProgress = true
      equal(c.modalContent(), subContent, 'returns subAccountModalContent')
    })

    test('renders a Modal', () => {
      const c = new ThemeEditorModal(props)
      const modalOpen = {}
      sinon.stub(c, 'modalOpen').returns(modalOpen)
      const modalContent = {}
      sinon.stub(c, 'modalContent').returns(modalContent)
      const vdom = c.render()
      equal(vdom.type, Modal, 'renders a Modal component')
      equal(vdom.props.isOpen, modalOpen, 'passes isOpen as prop')
      equal(vdom.props.children, modalContent, 'passes modelContent as child')
    })
  }
)
