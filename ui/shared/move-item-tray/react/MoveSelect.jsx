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

import React from 'react'
import {arrayOf, func} from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {positions} from '@canvas/positions'
import SelectPosition, {RenderSelect} from '@canvas/select-position'
import {Button} from '@instructure/ui-buttons'
import {Text as InstText} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {fetchItemTitles} from '@canvas/context-modules/utils/fetchItemTitles'
import {itemShape, moveOptionsType} from './propTypes'

const I18n = createI18nScope('move_select')

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

  fetchItems() {
    fetchItemTitles(ENV.COURSE_ID, this.state.selectedGroup.id)
      .then(items => {
        const groupitems = items.map(item => ({id: String(item.id), title: item.title}))
        this.setState(state => {
          const selectedGroup = state.selectedGroup
          selectedGroup.items = groupitems
          return {
            selectedGroup,
          }
        })
      })
      .catch(error => {
        this.setState(state => {
          const selectedGroup = state.selectedGroup
          selectedGroup.items = error
          return {
            selectedGroup,
          }
        })
      })
  }

  componentDidMount() {
    const {selectedGroup} = this.state
    if (selectedGroup && selectedGroup.items === undefined) {
      this.fetchItems()
    }
  }

  componentDidUpdate(_prevProps, prevState) {
    const {selectedGroup} = this.state
    const prevSelectedGroup = prevState.selectedGroup

    // Only fetch items if we have a selected group that's different from the previous one
    // and it doesn't have items loaded yet
    if (
      selectedGroup &&
      (!prevSelectedGroup || prevSelectedGroup.id !== selectedGroup.id) &&
      selectedGroup.items === undefined
    ) {
      this.fetchItems()
    }
  }

  renderSelectGroup() {
    const {selectedGroup, selectedPosition} = this.state
    const {items} = this.props
    const groups = this.getFilteredGroups(this.props)
    return (
      <div>
        <RenderSelect
          label={this.props.moveOptions.groupsLabel ? this.props.moveOptions.groupsLabel : null}
          className="move-select__group"
          onChange={this.selectGroup}
          options={groups.map(group => (
            <option key={group.id} value={group.id}>
              {group.title}
            </option>
          ))}
          selectOneDefault={false}
        />

        <SelectPosition
          items={items}
          siblings={selectedGroup?.items}
          selectedPosition={selectedPosition}
          selectPosition={this.selectPosition}
          selectSibling={this.selectSibling}
        />
      </div>
    )
  }

  render() {
    const {groups, siblings} = this.props.moveOptions
    const {items} = this.props
    const {selectedPosition} = this.state
    return (
      <div className="move-select">
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
