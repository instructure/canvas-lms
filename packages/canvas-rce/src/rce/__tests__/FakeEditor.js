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

export default class FakeEditor {
  constructor(props = {}) {
    this.props = props
    this.id = props.id || 'ed_id'
    this._initialValue = props.initialValue || ''
    this._onEditorChange = props.onEditorChange
    this.rceWrapper = {
      getCanvasUrl: () => {
        'https://mycanvas.com:3000'
      },
    }
    this.hidden = false
    this.callbacks = {}
    this.readonly = false

    this._selectedNode = null

    this._collapsed = false
    this._eventHandlers = {}

    this.mode = {
      set: mode => {
        this.readonly = mode === 'readonly'
      },
    }

    this.getContainer = () => this._$holder
    this.getContentAreaContainer = () => this._$holder
    this.getElement = () => document.querySelector(`textarea#${this.id}`)
    this.getBody = () => this._document.body
    this.getWin = () => this._$iframe.contentWindow

    this.isHidden = () => this.hidden
    this.hide = () => (this.hidden = true)
    this.show = () => (this.hidden = false)

    this.getContent = () => this._$contentBody.innerHTML
    this.setContent = content => {
      this._$contentBody.innerHTML = content
      this._onEditorChange?.(content)
    }

    this.execCommand = (command, _ui, value) => {
      switch (command) {
        case 'mceInsertContent': {
          this._$contentBody.innerHTML += value
          return true
        }
      }
    }

    this.selection = {
      startOffset: 0,
      endOffset: 0,
      startContainer: null,
      endContainer: null,
      getEnd: () => 0,
      getNode: () => this._selectedNode,

      getContent: () => (this._selectedNode ? this._selectedNode.outerHTML : ''),

      normalize: () => {},
      setContent: contentString => {
        if (this._selectedNode) {
          this._selectedNode.remove()
        }
        const $temp = document.createElement('div')
        $temp.innerHTML = contentString
        this._selectedNode = this._$contentBody.appendChild($temp.firstChild)
      },
      setAnchorOffset: offset => {
        this._anchorOffset = offset
      },
      setRng: range => {
        this._range = range
      },
      getRng: () => this._range,
      collapse: () => (this._collapsed = true),
      isCollapsed: () => this._collapsed,
      select: node => (this._selectedNode = node),
      setCursorLocation: () => {},
      getSel: () => {
        return {
          anchorNode: {
            ...this._selectedNode,
            wholeText: this._selectedNode?.textContent?.trim(),
          },
          anchorOffset: this._anchorOffset,
        }
      },
      getBookmark: () => {},
      moveToBookmark: () => {},
    }

    this.dom = {
      doc: this._document,
      getParent: (el, selector) => {
        let ancestor = el && el.parentNode
        while (ancestor) {
          const candidate = ancestor.querySelector(selector)
          if (candidate) return candidate
          ancestor = ancestor.parentNode
        }
        return null
      },
      setAttrib: (elem, attr, value) => {
        elem.setAttribute(attr, value)
      },
      getAttrib: (elem, attr) => {
        return elem.getAttribute(attr)
      },
      setAttribs: (elem, hash) => {
        Object.keys(hash).forEach(k => {
          if (hash[k] == undefined) {
            elem.removeAttribute(k)
          } else {
            elem.setAttribute(k, hash[k])
          }
        })
      },
      setStyles: (elem, hash) => {
        Object.keys(hash).forEach(k => {
          elem.style[k] = hash[k]
        })
      },
      replace: (newelem, oldelem) => {
        return oldelem.parentNode.replaceChild(newelem, oldelem)
      },
      select: selector => this._$contentBody.querySelectorAll(selector),
      remove: elem => elem.remove(),
    }

    this.ui = {
      registry: {
        addIcon: () => {},
      },
    }

    this.undoManager = {
      ignore: action => {
        action()
      },
    }

    this.serializer = {
      serialize: (elem, opts) => {
        if (!elem) return ''
        return opts.getInner ? elem.innerHTML : elem.outerHTML
      },
    }

    this.isDirty = () => {
      return this.getContent() !== this._initialValue
    }

    this.initialize()
  }

  get $container() {
    return this._$contentBody
  }

  get $iframe() {
    return this._$iframe
  }

  initialize() {
    this.uninitialize()

    this._$holder = document.createElement('div')
    this._$holder.className = 'fakeEditor tox'
    this._$holder.setAttribute('role', 'document')
    document.body.appendChild(this._$holder)

    this._$iframe = document.createElement('iframe')
    this._$holder.appendChild(this._$iframe)

    this.dom.doc = this._document = this._$iframe.contentDocument
    this._document.body.setAttribute('contenteditable', 'true')
    this._$contentBody = this._document.body
    this._$contentBody.innerHTML = this._initialValue
    this._$contentBody.tabIndex = '0'
    this.props.init?.setup?.(this)
  }

  uninitialize() {
    if (this._document) this._document.body.innerHTML = ''
  }

  appendElement($element) {
    this._$contentBody.appendChild($element)
  }

  setSelectedNode($element) {
    this._selectedNode = $element
  }

  focus() {
    this._$contentBody.focus()
  }

  fire(eventName, ...args) {
    const cb = this.callbacks[eventName]
    if (typeof cb === 'function') {
      cb(...args)
    }
  }

  on(eventName, callback) {
    this.callbacks[eventName] = callback
    if (eventName === 'input') {
      this.getBody().addEventListener('input', callback)
    }
  }
}
