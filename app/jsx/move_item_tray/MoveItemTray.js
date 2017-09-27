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
import I18n from 'i18n!move_item_tray';
import { string, bool, func, arrayOf, shape } from 'prop-types';
import Tray from 'instructure-ui/lib/components/Tray';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import Select from 'instructure-ui/lib/components/Select'
import Heading from 'instructure-ui/lib/components/Heading';
import Button from 'instructure-ui/lib/components/Button';
import ConnectorIcon from 'jsx/move_item_tray/ConnectorIcon';

const itemShape = shape({
  id: string,
  title: string
})

export default class MoveItemTray extends React.Component {
  static propTypes = {
    title: string,
    currentItem: itemShape.isRequired, // The chosen item to be inserted into the main list
    moveSelectionList: arrayOf(shape({
      item: shape({
        attributes:
          itemShape
        })
      })), // Array of all the elements except the current item
    initialOpenState: bool, // Determine the state of the moving item tray at start
    onExited: func,
    onMoveTraySubmit: func.isRequired
  };

  static defaultProps = {
    title: '',
    currentItem: {
      id: '',
      title: ''
    },
    moveSelectionList: [],
    initialOpenState: true,
    onExited: () => {},
  };

  constructor(props) {
    super(props);

    this.state = {
      open: this.props.initialOpenState,
      error: false,
      currentAction: ''
    }
  };

  onChangePlacement = (e) => {
    this.setState({
      currentAction: e.target.value
    });
    if(e.target.value === 'first' || e.target.value === 'last') {
      this.onChangeAbsoluteMove(e.target.value);
    } else if(this.relativeSelect) {
      this.relativeSelect.value = 'default';
    }
  };

  onChangeAbsoluteMove = (action) => {
    let vals = this.props.moveSelectionList.map((item) => item.attributes.id)
    switch(action)
    {
      case 'first':
        vals = [this.props.currentItem.id, ...vals]
        this.props.onMoveTraySubmit({movedItems: vals, action: 'first',
          currentID: this.props.currentItem.id, relativeID: vals[1]})
        break
      case 'last':
        vals.push(this.props.currentItem.id);
        this.props.onMoveTraySubmit({movedItems: vals, action: 'last',
          currentID: this.props.currentItem.id, relativeID: vals[vals.length - 2]})
        break
      default:
        break
    }
  };

  onChangeRelativeMove = (e) => {
    const vals = this.props.moveSelectionList.map((item) => item.attributes.id)
    const index = vals.indexOf(e.target.value);
    if(index === -1) return;
    switch(this.state.currentAction)
    {
      case 'after':
        vals.splice(index + 1, 0, this.props.currentItem.id);
        this.props.onMoveTraySubmit({ movedItems: vals, action: this.state.currentAction,
          currentID: this.props.currentItem.id, relativeID:  e.target.value })
        break
      case 'before':
        vals.splice(index, 0, this.props.currentItem.id);
        this.props.onMoveTraySubmit({ movedItems: vals, action: this.state.currentAction,
          currentID: this.props.currentItem.id, relativeID:  e.target.value })
        break
      default:
        break
    }
  }

  toggleSideBar = () => {
    this.setState({
      open: !this.state.open
    });
  }

  closeSideBar = () => {
    this.setState({
      open: false
    });
  };

  renderItemsSelect() {
    if (this.state.currentAction === 'after' || this.state.currentAction === 'before') {
      return (
        <div className="move-item-tray__input-box">
          <Select
            label={<ScreenReaderContent>{I18n.t('selected item')}</ScreenReaderContent>}
            messages={this.state.error ? [{text: I18n.t('Please select an item'), type: 'error'}] : []}
            onChange={this.onChangeRelativeMove}
            selectRef={(el) => this.relativeSelect = el }
            className="move-item-tray__input-box"
            >
            <option value="default">{I18n.t('Select One')}</option>
            {
              this.props.moveSelectionList.map((item) =>
                <option key={item.attributes.id} value={item.attributes.id}>{item.attributes.title || item.attributes.name}</option>
              )
            }
          </Select>
        </div>
      );
    }
  }

  render () {
    return (
        <Tray
          label={I18n.t('Move Item')}
          open={this.state.open}
          onDismiss={this.closeSideBar}
          onExited={this.props.onExited}
          closeButtonLabel={I18n.t('close move tray')}
          placement="end"
          applicationElement={() => document.getElementById('application')}
          closeButtonVariant="icon"
          shouldCloseOnDocumentClick
          shouldContainFocus
        >
          <div className="move-item-tray">
            <div className="move-item-tray__header">
              <Heading level="h4">{this.props.title}</Heading>
            </div>
            <div className="move-item-tray__content">
              <div className="move-item-tray__connector">
                {(this.state.currentAction === 'after' || this.state.currentAction === 'before') ? <ConnectorIcon/> : null}
              </div>
              <div className="move-item-tray__input-boxes">
                <div className="move-item-tray__input-box">
                  <Select
                    label={I18n.t(`Place "%{item}"`, {item: this.props.currentItem.title})}
                    messages={this.state.error ? [{text: I18n.t('Please select an item'), type: 'error'}] : []}
                    onChange={this.onChangePlacement}
                  >
                    <option value="default">{I18n.t('Select One')}</option>
                    <option value="first">{I18n.t('At the top')}</option>
                    <option value="before">{I18n.t('Before...')}</option>
                    <option value="after">{I18n.t('After...')}</option>
                    <option value="last">{I18n.t('At the bottom')}</option>
                  </Select>
                </div>
                {this.renderItemsSelect()}
              </div>
            </div>
            <div className="move-item-tray__button-container">
              <Button variant="primary" onClick={this.closeSideBar} className="move-item-tray__button">{I18n.t('Done')}</Button>
            </div>
          </div>
        </Tray>
    );
  };
}
