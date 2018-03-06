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

import I18n from 'i18n!move_select'
import React from 'react'
import { func, arrayOf } from 'prop-types'
import Select from '@instructure/ui-core/lib/components/Select'
import Button from '@instructure/ui-core/lib/components/Button'
import Container from '@instructure/ui-core/lib/components/Container'
import Text from '@instructure/ui-core/lib/components/Text'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'

import ConnectorIcon from './ConnectorIcon'
import { itemShape, moveOptionsType } from './propTypes'
import { positions } from './positions'

export default class MoveSelect extends React.Component {
  static propTypes = {
    items: arrayOf(itemShape).isRequired,
    moveOptions: moveOptionsType.isRequired,
    onSelect: func.isRequired,
    onClose: func.isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      selectedGroup: this.props.moveOptions.groups && this.getFilteredGroups()[0],
      selectedPosition: positions.first,
      selectedSibling: 0,
    }
  }

  selectGroup = (e) => {
    this.setState({ selectedGroup: this.props.moveOptions.groups.find(group => group.id === e.target.value) || null })
  }

  selectPosition = (e) => {
    this.setState({ selectedPosition: positions[e.target.value] || null })
  }

  selectSibling = (e) => {
    this.setState({ selectedSibling: e.target.value === '' ? 0 : Number(e.target.value) })
  }

  submitSelection = () => {
    const { items, moveOptions } = this.props
    const { selectedGroup, selectedPosition, selectedSibling } = this.state
    let order = items.map(({ id }) => id)
    if (selectedPosition) {
      const itemsInGroup = selectedGroup ? selectedGroup.items : moveOptions.siblings
      order = selectedPosition.apply({
        items: items.map(({ id }) => id),
        order: itemsInGroup.map(({ id }) => id),
        relativeTo: selectedSibling,
      })
    }

    this.props.onSelect({
      groupId: moveOptions.groups ? selectedGroup.id : null,
      itemIds: items.map(({ id }) => id),
      order,
    })
  }

  hasSelectedPosition () {
    const { selectedSibling, selectedPosition } = this.state
    const isAbsolute = selectedPosition && selectedPosition.type === 'absolute'
    return !!selectedPosition && (isAbsolute || selectedSibling !== null)
  }

  getFilteredGroups() {
    const { moveOptions, items } = this.props
    let { groups } = moveOptions
    if (moveOptions.excludeCurrent && items[0].groupId) {
      groups = groups.filter(group => group.id !== items[0].groupId)
    }
    return groups
  }

  isDoneSelecting () {
    const { selectedGroup } = this.state
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

  renderSelect ({ label, onChange, options, className,  selectOneDefault}) {
    return (
      <Container margin="medium 0" display="block" className={className}>
        <Select
          label={<ScreenReaderContent>{label}</ScreenReaderContent>}
          onChange={onChange}
          >
          {selectOneDefault && (<option>{I18n.t('Select one')}</option>)}
          {options}
        </Select>
      </Container>
    )
  }

  renderSelectGroup () {
    const { selectedGroup } = this.state
    const selectPosition = !!(selectedGroup && selectedGroup.items && selectedGroup.items.length)
    const groups = this.getFilteredGroups(this.props)
    return (
      <div>
        {this.renderSelect({
          label: I18n.t('Group Select'),
          className: 'move-select__group',
          onChange: this.selectGroup,
          options: groups.map(group =>
            <option key={group.id} value={group.id}>{group.title}</option>),
          selectOneDefault: false
        })}
        {selectPosition ? this.renderSelectPosition(selectedGroup.items) : null}
      </div>
    )
  }

  renderSelectPosition (items) {
    const { selectedPosition } = this.state
    const selectSibling = !!(selectedPosition && selectedPosition.type === 'relative')
    return (
      <div>
        {this.renderPlaceTitle()}
        {this.renderSelect({
          label: I18n.t('Position Select'),
          className: 'move-select__position',
          onChange: this.selectPosition,
          options: Object.keys(positions).map((pos) =>
            <option key={pos} value={pos}>{positions[pos].label}</option>),
          selectOneDefault: false
        })}
        {selectSibling ? (
          <div>
            <ConnectorIcon aria-hidden style={{ position: 'absolute', transform: 'translate(-15px, -35px)' }} />
            {this.renderSelectSibling(items)}
          </div>) : null}
      </div>
    )
  }

  renderSelectSibling (items) {
    const filteredItems = items.filter(item => item.id !== this.props.items[0].id)
    return this.renderSelect({
      label: I18n.t('Item Select'),
      className: 'move-select__sibling',
      onChange: this.selectSibling,
      options: filteredItems.map((item, index) =>
        <option key={item.id} value={index}>{item.title}</option>),
      selectOneDefault: false
    })
  }

  renderPlaceTitle() {
    const title = (this.props.moveOptions.groups) ?
      I18n.t('Place') :
      I18n.t('Place "%{title}"', { title: this.props.items[0].title })
    return (
      <Text paragraphMargin="medium 0" weight="bold">{title}</Text>
    );
  }

  render () {
    const { siblings, groups } = this.props.moveOptions
    return (
      <div className="move-select">
        {this.props.moveOptions.groupsLabel &&
          <Text paragraphMargin="medium 0" weight="bold">{this.props.moveOptions.groupsLabel}</Text>}
        {groups
          ? this.renderSelectGroup()
          : this.renderSelectPosition(siblings)}
        {(
          <Container textAlign="end" display="block">
            <hr />
            <Button id="move-item-tray-cancel-button" onClick={this.props.onClose} margin="0 x-small 0 0">{I18n.t('Cancel')}</Button>
            <Button
              id="move-item-tray-submit-button"
              disabled={!this.isDoneSelecting()}
              type="submit" variant="primary"
              onClick={this.submitSelection}
              margin="0 x-small 0 0">{I18n.t('Move')}</Button>
          </Container>
        )}
      </div>
    )
  }
}
