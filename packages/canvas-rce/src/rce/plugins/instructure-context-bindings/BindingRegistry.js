/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import EditorLink from './EditorLink'

/*
 * Find each "aux container" in the DOM. There might be more than one, depending
 * on if multiple instances of TinyMCE exist. To avoid misidentifying "aux
 * containers" which have already been linked with an editor, remove those from
 * the results.
 */
function getUnclaimedAuxContainers(editorLinks) {
  const $auxContainers = [...document.querySelectorAll('.tox-tinymce-aux')]
  return $auxContainers.filter($auxContainer => {
    return !editorLinks.some(editorLink => editorLink.$auxContainer === $auxContainer)
  })
}

export default class BindingRegistry {
  constructor() {
    this.editorLinks = []
  }

  /*
   * Remove all bound behavior (e.g. between specs).
   */
  reset() {
    ;[...this.editorLinks].forEach(editorLink => {
      this.unlinkEditor(editorLink.editor)
    })
  }

  /*
   * Establish a link with a TinyMCE Editor. Called when an Editor is
   * initialized.
   */
  linkEditor(editor) {
    const editorLink = this.getEditorLink(editor)
    if (editorLink == null) {
      this.editorLinks.push(new EditorLink(editor))
    }
  }

  /*
   * Establish a link with a TinyMCE Editor. Called when an Editor is
   * destroyed.
   */
  unlinkEditor(editor) {
    const editorLink = this.getEditorLink(editor)
    if (editorLink != null) {
      editorLink.remove()
      this.editorLinks = this.editorLinks.filter(link => link != editorLink)
    }
  }

  /*
   * Find and return the EditorLink created for the given TinyMCE Editor.
   */
  getEditorLink(editor) {
    return this.editorLinks.find(link => link.editor === editor)
  }

  /*
   * Register a ContextForm with TinyMCE. This wrapper expects a label and at
   * least one command (button) from the configuration for the ContextForm.
   * Those are used to identify the DOM elements associated with the ContextForm
   * after its creation and to emulate a lifecycle for it.
   */
  addContextForm(editor, name, config) {
    const contextLabel = config.label
    const [command, ...commands] = config.commands
    const onSetup = command.onSetup || (() => {})

    const amendedCommand = {...command}
    amendedCommand.onSetup = (...args) => {
      this.bindToolbarToEditor(editor, contextLabel)
      return onSetup(...args)
    }

    const amendedConfig = {...config, commands: [amendedCommand, ...commands]}
    editor.ui.registry.addContextForm(name, amendedConfig)

    const defaultFocusSelector = `.tox-toolbar-textfield[aria-label="${contextLabel}"]`
    this.addContextKeydownListener(editor, defaultFocusSelector)
  }

  addContextKeydownListener(editor, defaultFocusSelector) {
    editor.on('keydown', event => {
      // Alt+F7 is used to "enter into" the context's popover.
      if (event.keyCode === 118 && event.altKey) {
        const editorLink = this.getEditorLink(editor)

        /*
         * When Alt+F7 was pressed and the EditorLink does not yet have an "aux
         * container," that means the shortcut was used before any context has
         * been created. Take no action.
         */
        if (editorLink == null || editorLink.$auxContainer == null) {
          return
        }

        /*
         * Attempt to find the default focus element for this context using the
         * EditorLink's "aux container." If found, focus on it.
         */
        const $focusable = editorLink.$auxContainer.querySelector(defaultFocusSelector)

        if ($focusable) {
          $focusable.focus()
          event.preventDefault()
        }
      }
    })
  }

  bindToolbarToEditor(editor, toolbarLabel) {
    const editorLink = this.getEditorLink(editor)
    if (editorLink != null) {
      let $auxContainers
      if (editorLink.$auxContainer) {
        // This editor already has an known "aux container." Use it exclusively.
        $auxContainers = [editorLink.$auxContainer]
      } else {
        // Find an "aux container" not linked to an editor.
        $auxContainers = getUnclaimedAuxContainers(this.editorLinks)
      }
      editorLink.addBinding(toolbarLabel, $auxContainers)
    }
  }
}

export let globalRegistry = new BindingRegistry()
