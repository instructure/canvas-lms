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
import Container from 'instructure-ui/lib/components/Container';
import Heading from 'instructure-ui/lib/components/Heading';
import Select from 'instructure-ui/lib/components/Select'
import Button from 'instructure-ui/lib/components/Button';
import ConnectorIcon from 'jsx/move_item_tray/ConnectorIcon';

const itemShape = shape({
  id: string,
  title: string
})

const parentGroupShape = shape({
  groupId: string,
  title: string,
  children: arrayOf(shape({
    attributes: shape({
      id: string,
      name: string
    })
  }))
})

export default class NestedMoveItemTray extends React.Component {
  static propTypes = {
    title: string,
    currentItem: itemShape.isRequired, // The chosen item to be inserted into the main list
    initialOpenState: bool, // Determine the state of the moving item tray at start
    onExited: func,
    onMoveTraySubmit: func.isRequired,
    parentGroups: arrayOf(parentGroupShape).isRequired,
    parentTitleLabel: string.isRequired
  };

  static defaultProps = {
    title: '',
    currentItem: {
      id: '',
      title: ''
    },
    initialOpenState: true,
    onExited: () => {},
  };

  constructor(props) {
    super(props);

    this.state = {
      open: this.props.initialOpenState,
      error: false,
      currentGroup: ''
    }
  };

  onHandleSelectGroup = (e) => {
    this.setState({
      currentGroup: e.target.value
    });
    if(this.childrenSelect) {
      this.childrenSelect.value = 'default';
    }
  };

  onHandleSelectChild = (e) => {
    const currentMoveList = this.props.parentGroups.find((x) => x.groupId === this.state.currentGroup)
      .children.map((item) => item.attributes.id );

    if(e.target.value === "bottom") {
      currentMoveList.push(this.props.currentItem.id);
      this.props.onMoveTraySubmit(currentMoveList, this.state.currentGroup);
    } else {
      const index = currentMoveList.indexOf(e.target.value);
      if(index === -1) return;
      currentMoveList.splice(index, 0, this.props.currentItem.id);
      this.props.onMoveTraySubmit(currentMoveList, this.state.currentGroup)
    }
  };

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
    if (this.state.currentGroup) {
      return (
        <div className="move-item-tray__input-box">
          <Select
            label={I18n.t('Before...')}
            messages={this.state.error ? [{text: I18n.t('Please select an item'), type: 'error'}] : []}
            onChange={this.onHandleSelectChild}
            selectRef={(el) => { this.childrenSelect = el } }
            className="move-item-tray__input-box"
            >
            <option value="default">{I18n.t('Select One')}</option>
            {
              this.props.parentGroups.find((x) => x.groupId === this.state.currentGroup).children.map((item) =>
                <option key={item.attributes.id} value={item.attributes.id}>{item.attributes.title || item.attributes.name}</option>
              )
            }
            <option value="bottom">{I18n.t('--At the bottom--')}</option>
          </Select>
        </div>
      );
    } else {
      return null
    }
  }

  render () {
    return (
      <Tray
        label={this.props.parentTitleLabel}
        open={this.state.open}
        onDismiss={this.closeSideBar}
        onExited={this.props.onExited}
        placement="end"
        applicationElement={() => document.getElementById('application')}
        closeButtonLabel={I18n.t('close move tray')}
        closeButtonVariant="icon"
        shouldCloseOnDocumentClick
        shouldContainFocus
      >
        <Container className="move-item-tray">
          <div className="move-item-tray__header">
            <Heading level="h4">{this.props.title}</Heading>
          </div>
          <div className="move-item-tray__content">
            <div className="move-item-tray__connector">
              {(this.state.currentGroup) ? <ConnectorIcon/> : null}
            </div>
            <div className="move-item-tray__input-boxes">
              <div className="move-item-tray__input-box">
                <Select
                  label={I18n.t('Place "%{item}"', {item: this.props.currentItem.title})}
                  messages={this.state.error ? [{text: I18n.t('Please select an item'), type: 'error'}] : []}
                  onChange={this.onHandleSelectGroup}
                >
                  <option value="">{I18n.t('Select One')}</option>
                  {
                    this.props.parentGroups.map((item) =>
                      <option key={item.groupId} value={item.groupId}>{item.title || item.name}</option>
                    )
                  }
                </Select>
              </div>
              {this.renderItemsSelect()}
            </div>
          </div>
          <div className="move-item-tray__button-container">
            <Button variant="primary" onClick={this.closeSideBar} className="move-item-tray__button">{I18n.t('Done')}</Button>
          </div>
        </Container>
      </Tray>
    );
  };
}
