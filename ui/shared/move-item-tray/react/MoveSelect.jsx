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

import {arrayOf, func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {itemShape, moveOptionsType} from './propTypes'
import {positions} from '@canvas/positions'
import SelectPosition, {RenderSelect} from '@canvas/select-position'
import React from 'react'

import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('move_select')

export default class MoveSelect extends React.Component {
  static propTypes = {
    items: arrayOf(itemShape).isRequired,
    moveOptions: moveOptionsType.isRequired,
    onSelect: func.isRequired,
    onClose: func.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      selectedGroup: this.props.moveOptions.groups && this.getFilteredGroups()[0],
      selectedPosition: positions.first,
      selectedSibling: 0,
    }
  }

  selectGroup = e => {
    this.setState({
      selectedGroup:
        this.props.moveOptions.groups.find(group => group.id === e.target.value) || null,
    })
  }

  selectPosition = e => {
    this.setState({selectedPosition: positions[e.target.value] || null})
  }

  selectSibling = e => {
    this.setState({selectedSibling: e.target.value === '' ? 0 : Number(e.target.value)})
  }

  submitSelection = () => {
    const {items, moveOptions} = this.props
    const {selectedGroup, selectedPosition, selectedSibling} = this.state
    let order = items.map(({id}) => id)
    if (selectedPosition) {
      const itemsInGroup = selectedGroup ? selectedGroup.items : moveOptions.siblings
      order = selectedPosition.apply({
        items: items.map(({id}) => id),
        order: itemsInGroup.map(({id}) => id),
        relativeTo: selectedSibling,
      })
    }

    this.props.onSelect({
      groupId: moveOptions.groups ? selectedGroup.id : null,
      itemIds: items.map(({id}) => id),
      order,
    })
  }

  hasSelectedPosition() {
    const {selectedSibling, selectedPosition} = this.state
    const isAbsolute = selectedPosition && selectedPosition.type === 'absolute'
    return !!selectedPosition && (isAbsolute || selectedSibling !== null)
  }

  getFilteredGroups() {
    const {moveOptions, items} = this.props
    let {groups} = moveOptions
    if (moveOptions.excludeCurrent && items[0].groupId) {
      groups = groups.filter(group => group.id !== items[0].groupId)
    }
    return groups
  }

  isDoneSelecting() {
    const {selectedGroup} = this.state
    if (this.props.moveOptions.groups) {
      if (selectedGroup && selectedGroup.items && selectedGroup.items.length) {
        return this.hasSelectedPosition()
      } else {
        return !!selectedGroup
      }
    } else {
      return this.hasSelectedPosition()
    }
  }

  renderSelectGroup() {
    const {selectedGroup, selectedPosition} = this.state
    const {items} = this.props
    const selectPosition = !!(selectedGroup && selectedGroup.items && selectedGroup.items.length)
    const groups = this.getFilteredGroups(this.props)
    return (
      <div>
        <RenderSelect
          label={I18n.t('Group Select')}
          className="move-select__group"
          onChange={this.selectGroup}
          options={groups.map(group => (
            <option key={group.id} value={group.id}>
              {group.title}
            </option>
          ))}
          selectOneDefault={false}
        />
        {selectPosition ? (
          <SelectPosition
            items={items}
            siblings={selectedGroup.items}
            selectedPosition={selectedPosition}
            selectPosition={this.selectPosition}
            selectSibling={this.selectSibling}
          />
        ) : null}
      </div>
    )
  }

  render() {
    const {groups, siblings} = this.props.moveOptions
    const {items} = this.props
    const {selectedPosition} = this.state
    return (
      <div className="move-select">
        {this.props.moveOptions.groupsLabel && (
          <Text weight="bold">{this.props.moveOptions.groupsLabel}</Text>
        )}
        {groups ? (
          this.renderSelectGroup()
        ) : (
          <SelectPosition
            items={items}
            siblings={siblings}
            selectedPosition={selectedPosition}
            selectPosition={this.selectPosition}
            selectSibling={this.selectSibling}
          />
        )}
        <View textAlign="end" display="block">
          <hr aria-hidden="true" />
          <Button
            id="move-item-tray-cancel-button"
            onClick={this.props.onClose}
            margin="0 x-small 0 0"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            id="move-item-tray-submit-button"
            disabled={!this.isDoneSelecting()}
            type="submit"
            color="primary"
            onClick={this.submitSelection}
            margin="0 x-small 0 0"
          >
            {I18n.t('Move')}
          </Button>
        </View>
      </div>
    )
  }
}
