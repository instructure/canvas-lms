/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

type ElemType = {
  type: 'modulelist' | 'module' | 'item' | undefined
  elem: HTMLElement
}

class KBNavigator {
  getElemType(elem: HTMLElement): ElemType {
    const item = elem.closest('.context_module_item') as HTMLElement
    if (item) {
      return {type: 'item', elem: item}
    }

    const module = elem.closest('.context_module') as HTMLElement
    if (module) {
      return {type: 'module', elem: module}
    }

    const moduleList = elem.closest('.context_module_list') as HTMLElement
    if (moduleList) {
      return {type: 'modulelist', elem: moduleList}
    }

    return {type: undefined, elem}
  }

  isModuleExpanded(moduleElem: HTMLElement) {
    return moduleElem.classList.contains('expanded')
  }

  moduleTitle(moduleElem: HTMLElement) {
    return moduleElem.querySelector('.module_title') as HTMLElement
  }

  getModuleExpandCollapseButton(moduleElem: HTMLElement) {
    return moduleElem.querySelector('button[id*="module-header-expand-toggle-"]') as HTMLElement
  }

  itemTitle(itemElem: HTMLElement) {
    return itemElem.querySelector('a, button') as HTMLElement
  }

  getFocusableElem(elem: HTMLElement) {
    if (elem.classList.contains('context_module')) {
      return this.moduleTitle(elem) || this.getModuleExpandCollapseButton(elem)
    }
    if (elem.classList.contains('context_module_item')) {
      return this.itemTitle(elem)
    }
    return null
  }

  getPreviousSibling(elem: HTMLElement, containerSelector: string, childSelector: string) {
    const position = parseInt(elem.getAttribute('data-position') || '0', 10)
    const container = elem.closest(containerSelector) as HTMLElement
    const allCandidateChildren = Array.from(container.querySelectorAll(childSelector))
    for (let i = allCandidateChildren.length - 1; i >= 0; --i) {
      const pos = parseInt(allCandidateChildren[i].getAttribute('data-position') || '0', 10)
      if (pos < position) {
        return allCandidateChildren[i] as HTMLElement
      }
    }
    return null
  }

  getNextSibling(elem: HTMLElement, containerSelector: string, childSelector: string) {
    const position = parseInt(elem.getAttribute('data-position') || '0', 10)
    const container = elem.closest(containerSelector) as HTMLElement
    const allCandidateChildren = Array.from(container.querySelectorAll(childSelector))
    for (let i = 0; i < allCandidateChildren.length; ++i) {
      const pos = parseInt(allCandidateChildren[i].getAttribute('data-position') || '0', 10)
      if (pos > position) {
        return allCandidateChildren[i] as HTMLElement
      }
    }
    return null
  }

  getPreviousModule(elem: HTMLElement) {
    return this.getPreviousSibling(elem, '.context_module_list', '.context_module')
  }

  getNextModule(elem: HTMLElement) {
    return this.getNextSibling(elem, '.context_module_list', '.context_module')
  }

  getPreviousItem(elem: HTMLElement) {
    return this.getPreviousSibling(elem, '.context_module', '.context_module_item')
  }

  getNextItem(elem: HTMLElement) {
    return this.getNextSibling(elem, '.context_module', '.context_module_item')
  }

  /* *******************************************************
   * Arrow up/down assumes the <li> elements are all siblings
   * (not true for modules in the teacher view)
   ******************************************************* */

  // If on a module, moves focus to the next module
  // If on an item, moves focus to the next item
  // If on the last module or item, do nothing
  handleDown(type: ElemType): boolean {
    let next: HTMLElement | null = null

    if (type.type === 'modulelist') {
      next = document.querySelector('.context_module') as HTMLElement
    } else if (type.type === 'module') {
      if (this.isModuleExpanded(type.elem)) {
        // go to the first item
        next = type.elem.querySelector('.context_module_item') as HTMLElement
      }
      if (next === null) {
        next = this.getNextModule(type.elem)
      }
    } else if (type.type === 'item') {
      next = this.getNextItem(type.elem)
      if (next === null) {
        const parentModule = type.elem.closest('.context_module') as HTMLElement
        next = this.getNextModule(parentModule)
      }
    }

    if (next === null) return false

    next = this.getFocusableElem(next)
    next?.focus()
    return !!next
  }

  // If on a module, moves focus to the previous module
  // If on an item, moves focus to the previous item
  // If on the first module or item, do nothing
  handleUp(type: ElemType): boolean {
    if (type.type === 'modulelist') return false

    let prev: HTMLElement | null = null
    if (type.type === 'module') {
      prev = this.getPreviousModule(type.elem)
      if (prev && this.isModuleExpanded(prev)) {
        // move to the last item of the previous module
        const items = prev.querySelectorAll('.context_module_item')
        if (items.length > 0) {
          prev = items[items.length - 1] as HTMLElement
        }
      }
    }

    if (type.type === 'item') {
      prev = this.getPreviousItem(type.elem)
      if (prev === null) {
        // to to my parent module
        prev = type.elem.closest('.context_module') as HTMLElement
      }
    }

    if (prev === null) return false

    prev = this.getFocusableElem(prev)
    prev?.focus()
    return !!prev
  }

  // TODO: the selectors here are a bit dodgy
  handleEdit(_type: ElemType): boolean {
    // TODO: implement
    return false
  }

  handleDelete(_type: ElemType): boolean {
    // TODO: implement
    return false
  }

  handleIndent(_type: ElemType): boolean {
    // TODO: implement
    return false
  }

  handleOutdent(_type: ElemType): boolean {
    // TODO: implement
    return false
  }

  handleNew(type: ElemType): boolean {
    // TODO: implement
    return false
  }

  handleHelp(): boolean {
    const legendButton = document.getElementById('legend-button')
    if (!legendButton) return false

    const event = new Event('show-legend-action')
    legendButton.dispatchEvent(event)
    return true
  }

  // canvas kb shortcuts
  // see: https://community.canvaslms.com/t5/Canvas-Resource-Documents/Canvas-Keyboard-Shortcuts/ta-p/387069
  handleShortcutKey(event: KeyboardEvent) {
    if (['ArrowUp', 'ArrowDown', 'j', 'k', 'e', 'd', 'i', 'o', 'n', '?'].includes(event.key)) {
      if (event.ctrlKey || event.metaKey || event.altKey) return

      let elem = event.target as HTMLElement
      if (elem.id === 'content') {
        elem = document.querySelector('.context_module_list') as HTMLElement
      }
      const elemType = this.getElemType(elem)
      if (!elemType.type) return

      let handled: boolean = false
      switch (event.key) {
        case 'ArrowDown':
        case 'j':
          handled = this.handleDown(elemType)
          break
        case 'ArrowUp':
        case 'k':
          handled = this.handleUp(elemType)
          break
        case 'e':
          handled = this.handleEdit(elemType)
          break
        case 'd':
          handled = this.handleDelete(elemType)
          break
        case 'i':
          handled = this.handleIndent(elemType)
          break
        case 'o':
          handled = this.handleOutdent(elemType)
          break
        case 'n':
          handled = this.handleNew(elemType)
          break
        case '?':
          handled = this.handleHelp()
          break
      }
      if (handled) {
        event.preventDefault()
      }
    }
  }
}

const navigator = new KBNavigator()
const handleShortcutKey = navigator.handleShortcutKey.bind(navigator)

export {KBNavigator, handleShortcutKey}
