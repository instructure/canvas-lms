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
import { func } from 'prop-types';

export default class ColumnHeader extends React.Component {
  static propTypes = {
    addGradebookElement: func,
    removeGradebookElement: func
  };

  static defaultProps = {
    addGradebookElement () {},
    removeGradebookElement () {}
  };

  constructor (props) {
    super(props);

    this.handleKeyDown = this.handleKeyDown.bind(this);
  }

  state = { menuShown: false };

  bindOptionsMenuTrigger = (ref) => { this.optionsMenuTrigger = ref };

  bindSortByMenuContent = (ref) => {
    // instructure-ui components return references to react components.
    // At this time the only way to get dom node refs is via findDOMNode.
    if (ref) {
      // eslint-disable-next-line react/no-find-dom-node
      this.props.addGradebookElement(ReactDOM.findDOMNode(ref));
    } else {
      // eslint-disable-next-line react/no-find-dom-node
      this.props.removeGradebookElement(ReactDOM.findDOMNode(this.sortByMenuContent));
    }

    this.sortByMenuContent = ref;
  };

  bindOptionsMenuContent = (ref) => {
    // Dealing with add/removeGradebookElement in a convoluted combination of
    // this method and onToggle rather than the simpler way of calling those
    // methods directly (like in bindSortByMenuContent) because this method is
    // called by PopoverMenu three times when opening the menu. First with a ref
    // to the content, then with null, then again with a ref to the content.
    // We MUST get the DOM node here, rather than in onToggle because by the
    // time onToggle is called when closing the menu, the component has already
    // been unmounted and an error will be thrown if you attempt access.
    // instructure-ui components return references to react components.
    // At this time the only way to get dom node refs is via findDOMNode.
    if (ref) {
      this.optionsMenuContent = ref;
      // eslint-disable-next-line react/no-find-dom-node
      this.optionsMenuContentDOMNode = ReactDOM.findDOMNode(ref);
    }
  };

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

  onToggle = (show) => {
    this.setState({ menuShown: show }, () => {
      if (show) {
        this.props.addGradebookElement(this.optionsMenuContentDOMNode);
      } else {
        this.props.removeGradebookElement(this.optionsMenuContentDOMNode);
        this.optionsMenuContent = null;
        this.optionsMenuContentDOMNode = null;
      }
    });
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
