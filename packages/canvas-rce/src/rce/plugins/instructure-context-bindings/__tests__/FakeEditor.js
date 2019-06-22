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
  constructor($parentContainer) {
    this.$parentContainer = $parentContainer

    this._eventHandlers = {
      keydown: []
    }
    this._registryData = {
      contextForms: {}
    }

    this.ui = {
      registry: {
        addContextForm: (identifier, config) => {
          this._registryData.contextForms[identifier] = config
        }
      }
    }

    this.focus = jest.fn()

    this.selection = {
      collapse: jest.fn(),

      getNode() {
        return null // Not concerned about this behavior at this time
      },

      isCollapsed() {
        return false // Not concerned about this behavior at this time
      }
    }
  }

  setup() {
    this.$auxContainer = this.$parentContainer.appendChild(document.createElement('div'))
    this.$auxContainer.classList.add('tox', 'tox-silver-sink', 'tox-tinymce-aux')
  }

  teardown() {
    this.$auxContainer.remove()
  }

  on(eventName, handler) {
    this._eventHandlers[eventName] = this._eventHandlers[eventName] || []
    this._eventHandlers[eventName].push(handler)
  }

  off(eventName, handler) {
    this._eventHandlers[eventName] = this._eventHandlers[eventName].filter(
      eventHandler => eventHandler != handler
    )
  }

  triggerEvent(event) {
    ;(this._eventHandlers[event.type] || []).forEach(handler => handler(event))
  }

  registerContextForm(identifier, config) {
    this._registryData.contextForms[identifier] = config
  }

  showContextForm(identifier) {
    const {commands, label} = this._registryData.contextForms[identifier]

    const $contextContainer = document.createElement('div')
    $contextContainer.classList.add('tox-pop')

    const buttonHtmls = commands.map(
      command => `
      <button aria-label="${command.tooltip}" title="${
        command.tooltip
      }" type="button" tabindex="-1" class="tox-tbtn" aria-pressed="false">
      </button>
    `
    )

    $contextContainer.innerHTML = `
      <div class="tox-pop__dialog">
        <div role="group" class="tox-toolbar">
          <div role="toolbar" data-alloy-tabstop="true" tabindex="-1" class="tox-toolbar__group">
            <input type="text" aria-label="${label}" tabindex="-1" class="tox-toolbar-textfield">
          </div>

          <div role="toolbar" data-alloy-tabstop="true" tabindex="-1" class="tox-toolbar__group">
            ${buttonHtmls.join('')}
          </div>
        </div>
      </div>
    `

    this.$auxContainer.appendChild($contextContainer)

    /*
     * Emulate each button's lifecycle by calling the `onSetup` callback when it
     * renders.
     */
    commands.forEach(command => {
      if (command.onSetup) {
        command.onSetup(/* buttonApi */)
      }
    })

    return $contextContainer
  }
}
