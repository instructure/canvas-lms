/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react';
import ReactDOM from 'react-dom';
import AssignmentRowCell from '../../../../gradezilla/default_gradebook/components/AssignmentRowCell';

class AssignmentCellEditor {
  constructor (options) {
    this.options = options;
    this.container = options.container;
    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.renderComponent();
    options.column.getGridSupport().events.onKeyDown.subscribe(this.handleKeyDown);
  }

  renderComponent () {
    const bindComponent = (ref) => { this.component = ref };
    const props = {
      ...this.options.column.propFactory.getProps(this.options.item),
      ref: bindComponent,
      editorOptions: this.options
    };

    const element = React.createElement(AssignmentRowCell, props, null);
    ReactDOM.render(element, this.container);
  }

  handleKeyDown (event) {
    if (this.component) {
      return this.component.handleKeyDown(event);
    }
  }

  destroy () {
    this.component = null;
    this.options.column.getGridSupport().events.onKeyDown.unsubscribe(this.handleKeyDown);
    ReactDOM.unmountComponentAtNode(this.container);
  }

  focus () {
    this.component.focus();
  }

  isValueChanged () {
    return this.component.isValueChanged();
  }

  serializeValue () {
    return this.component.serializeValue();
  }

  loadValue (item) {
    this.component.loadValue(item);
    this.renderComponent();
  }

  applyValue (item, state) {
    this.component.applyValue(item, state);
  }

  validate () {
    return this.component.validate();
  }
}

export default AssignmentCellEditor;
