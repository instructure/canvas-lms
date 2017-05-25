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

export default class ColumnHeader extends React.Component {
  constructor (props) {
    super(props);

    this.handleKeyDown = this.handleKeyDown.bind(this);
  }

  bindOptionsMenuTrigger = (ref) => { this.optionsMenuTrigger = ref };
  bindOptionsMenuContent = (ref) => { this.optionsMenuContent = ref };

  focusAtStart = () => {
    if (this.optionsMenuTrigger) {
      this.optionsMenuTrigger.focus();
    }
  };

  focusAtEnd = () => {
    if (this.optionsMenuTrigger) {
      this.optionsMenuTrigger.focus();
    }
  };

  handleKeyDown (event) {
    if (document.activeElement === this.optionsMenuTrigger) {
      if (event.which === 13) { // Enter
        this.optionsMenuTrigger.click();
        return false; // prevent Grid behavior
      }
    }

    return undefined;
  }
}
