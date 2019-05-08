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

/*
 * The EditorLink exists to infer and maintain associations between a specific
 * TinyMCE Editor instance and the "aux container" created by the "silver" theme
 * to contain the popovers used for ContextForm and ContextToolbar.
 *
 * In TinyMCE, there is no apparent way to reference instances of those two
 * context types. This means the lifecycles around those instances are
 * completely intangible and must be inferred through other means. The related
 * DOM elements can be queried based on predictable classes and ARIA labels,
 * which can be observed to infer when a context has been established and/or
 * destroyed.
 *
 * An extra complication comes when multiple TinyMCE Editors exist in the same
 * document. Each will have its own "aux container," which means extra steps
 * must be taken to infer which editor instance belongs to which container based
 * on which contexts have been created.
 *
 * There are no guarantees with TinyMCE, so there is extra defensive code within
 * to help avoid problems that might or might not be possible.
 */

/*
 * Each child element within an "aux container" belongs to either a ContextForm
 * or a ContextToolbar. Based on the known label (taken from the configuration
 * given in the `addContextForm` or `addContextToolbar` call), locate the
 * container which contains an element with the matching ARIA label and return a
 * reference to that child container. This is a "context container."
 */
function findElementWithContextLabel(contextLabel, $auxContainer) {
  return [...$auxContainer.children].find($child =>
    $child.querySelector(`[aria-label="${contextLabel}"]`)
  )
}

/*
 * For a given context label, obtain a reference to its associated "context
 * container" and "aux container." Return those references, or null if no
 * associated elements can be found.
 */
function locateAuxContainersByContextLabel(contextLabel, $auxContainers) {
  for (const $auxContainer of $auxContainers) {
    const $contextContainer = findElementWithContextLabel(contextLabel, $auxContainer)
    if ($contextContainer != null) {
      return {$auxContainer, $contextContainer}
    }
  }

  return null
}

export default class EditorLink {
  constructor(editor) {
    this.editor = editor

    this.$auxContainer = null
    this.auxObserver = null
    this.bindings = []
  }

  /*
   * Ensure that the "aux container" for this editor is identified and observed.
   */
  ensureBoundAux($auxContainer) {
    /*
     * When the "aux container" is already observed, no further action is
     * required.
     */
    if (this.$auxContainer != null) {
      return
    }

    this.$auxContainer = $auxContainer

    this.auxObserver = new MutationObserver(mutationList => {
      mutationList.forEach(mutation => {
        /*
         * When the mutation removed a child, this means the context container
         * for a previously-bound context should have been removed. Remove the
         * related bindings for that context.
         */
        if (mutation.type === 'childList' && mutation.removedNodes) {
          ;[...mutation.removedNodes].forEach($element => {
            this.maybeRemoveBindingByElement($element)
          })
        }
      })
    })

    /*
     * Observe the "aux container" for changes only to its immediate children.
     */
    this.auxObserver.observe(this.$auxContainer, {
      attributes: false,
      childList: true,
      subtree: false
    })
  }

  bindContext(contextLabel, $contextContainer) {
    const keydownListener = event => {
      // 'Esc' to dismiss the context view
      if (event.keyCode === 27) {
        this.editor.selection.collapse()
        event.preventDefault()
      }

      // Alt+F7 to return focus to the editor
      if (event.keyCode === 118 && event.altKey) {
        this.editor.focus()
        event.preventDefault()
      }
    }

    $contextContainer.addEventListener('keydown', keydownListener, false)

    const remove = () => {
      $contextContainer.removeEventListener('keydown', keydownListener, false)
      this.bindings = this.bindings.filter(binding => binding.contextLabel !== contextLabel)
    }

    this.bindings.push({contextLabel, $contextContainer, remove})
  }

  remove() {
    if (this.auxObserver) {
      this.auxObserver.disconnect()
      this.auxObserver = null
      this.$auxContainer = null
    }
    this.bindings.forEach(binding => {
      binding.remove()
    })
  }

  addBinding(contextLabel, $auxContainers) {
    /*
     * Find the "aux container" and context container provided for the context
     * with the given label. If it somehow cannot be located, disregard it.
     */
    const location = locateAuxContainersByContextLabel(contextLabel, $auxContainers)
    if (location == null) {
      return
    }

    /*
     * When a context is being bound, it might be the first context to be bound
     * for this editor. When this happens, the "aux container" needs to be
     * discovered and observed.
     */
    this.ensureBoundAux(location.$auxContainer)

    /*
     * Remove the binding for the current label instead of the context
     * container, just in case the element containing the context has changed.
     * This should never be the case. But surprises happen.
     */
    this.removeBindingByLabel(contextLabel)
    this.bindContext(contextLabel, location.$contextContainer)
  }

  removeBindingByLabel(contextLabel) {
    const binding = this.getBindingByLabel(contextLabel)
    if (binding != null) {
      binding.remove()
    }
  }

  maybeRemoveBindingByElement($element) {
    const binding = this.getBindingByElement($element)
    /*
     * This is protection against cases which should not be possible. Best to be
     * sure, just in case.
     */
    if (binding == null || this.$auxContainer == null) {
      return
    }

    /*
     * When this editor's "aux container" no longer contains the context, this
     * should mean that the context has been destroyed and the bindings can be
     * removed.
     */
    if (!this.$auxContainer.contains(binding.$contextContainer)) {
      binding.remove()
    }
  }

  getBindingByLabel(contextLabel) {
    return this.bindings.find(binding => binding.contextLabel === contextLabel)
  }

  getBindingByElement($element) {
    return this.bindings.find(binding => binding.$contextContainer.contains($element))
  }
}
