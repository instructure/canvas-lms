// @ts-nocheck
/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'

/*
 * This editor is intended to be responsible for interfacing with SlickGrid and
 * hooking into any relevant lifecycle events. All other business concerns for
 * Cell behavior should be located within the specific Cell component.
 */
export default class ReactCellEditor {
  /*
   * `options` is provided by SlickGrid when instantiating the editor.
   */
  constructor(options) {
    this.options = options

    this.container = options.container
    this.handleKeyDown = this.handleKeyDown.bind(this)

    this.renderComponent()
    options.column.getGridSupport().events.onKeyDown.subscribe(this.handleKeyDown)
  }

  renderComponent() {
    const props = {
      ...this.options.column.propFactory.getProps(this.options),
      ref: ref => {
        this.component = ref
      },
    }

    /*
     * `createElement()` is required for subclasses to implement.
     */
    const element = this.createElement(props)
    ReactDOM.render(element, this.container)
  }

  handleKeyDown(event: KeyboardEvent) {
    if (this.component) {
      return this.component.handleKeyDown(event)
    }
  }

  /*
   * SlickGrid Editor Interface Method (required)
   *
   * `destroy` is called on the editor when the cell is exiting edit mode.
   * Within this method:
   *   • Bound events for the editor should be unbound.
   *   • DOM elements for the editor should be removed.
   *   • Transient data created for editing should be destroyed.
   */
  destroy() {
    this.component = null
    this.options.column.getGridSupport().events.onKeyDown.unsubscribe(this.handleKeyDown)
    ReactDOM.unmountComponentAtNode(this.container)
  }

  /*
   * SlickGrid Editor Interface Method (required)
   *
   * This is called when validation has failed. Focus will be forcibly reset to
   * the editor.
   */
  focus() {
    this.component.focus()
  }

  /*
   * SlickGrid Editor Interface Method (required)
   */
  isValueChanged() {
    return !!this.component && this.component.isValueChanged()
  }

  /*
   * SlickGrid Editor Interface Method (required)
   */
  serializeValue() {
    return null
  }

  /*
   * SlickGrid Editor Interface Method (required)
   *
   * @param {object} item – The data object for the row.
   */
  loadValue(/* item */) {
    this.renderComponent()
  }

  /*
   * SlickGrid Editor Interface Method (required)
   *
   * @param {object} item – The data object for the row.
   * @param {object|string|number|undefined|null} state – The serialized editor value.
   *
   * When the current edit is being committed, `applyValue` will be called to
   * handle the edited value. This is typically when the value is saved.
   */
  applyValue(/* item, state */) {
    this.component.applyValue()
  }

  /*
   * SlickGrid Editor Interface Method (required)
   */
  validate() {
    // SlickGrid validation is not to be used.
    return {msg: null, valid: true}
  }
}
