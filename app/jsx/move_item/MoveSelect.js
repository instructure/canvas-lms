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
import { func } from 'prop-types'
import Select from 'instructure-ui/lib/components/Select'
import Button from 'instructure-ui/lib/components/Button'
import Container from 'instructure-ui/lib/components/Container'
import Typography from 'instructure-ui/lib/components/Typography'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'

import ConnectorIcon from './ConnectorIcon'
import { itemShape, moveOptionsType } from './propTypes'
import { positions } from './positions'

export default class MoveSelect extends React.Component {
  static propTypes = {
    item: itemShape.isRequired,
    moveOptions: moveOptionsType.isRequired,
    onSelect: func.isRequired,
  }

  state = {
    selectedGroup: null,
    selectedPosition: null,
    selectedSibling: null,
  }

  selectGroup = (e) => {
    this.setState({ selectedGroup: this.props.moveOptions.groups.find(group => group.id === e.target.value) || null })
  }

  selectPosition = (e) => {
    this.setState({ selectedPosition: positions[e.target.value] || null })
  }

  selectSibling = (e) => {
    this.setState({ selectedSibling: e.target.value === '' ? null : Number(e.target.value) })
  }

  submitSelection = () => {
    const { item, moveOptions } = this.props
    const { selectedGroup, selectedPosition, selectedSibling } = this.state
    let order = [item.id]
    if (selectedPosition) {
      const items = selectedGroup ? selectedGroup.items : moveOptions.siblings
      order = selectedPosition.apply({
        item: item.id,
        order: items.map(({ id }) => id),
        relativeTo: selectedSibling,
      })
    }

    this.props.onSelect({
      groupId: moveOptions.groups ? selectedGroup.id : null,
      itemId: item.id,
      order,
    })
  }

  hasSelectedPosition () {
    const { selectedSibling, selectedPosition } = this.state
    const isAbsolute = selectedPosition && selectedPosition.type === 'absolute'
    return !!selectedPosition && (isAbsolute || selectedSibling !== null)
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

  renderSelect ({ label, onChange, options, className }) {
    return (
      <Container margin="medium 0" display="block" className={className}>
        <Select
          label={<ScreenReaderContent>{label}</ScreenReaderContent>}
          onChange={onChange}>
          <option>{I18n.t('Select one')}</option>
          {options}
        </Select>
      </Container>
    )
  }

  renderSelectGroup () {
    const { selectedGroup } = this.state
    const selectPosition = !!(selectedGroup && selectedGroup.items && selectedGroup.items.length)
    const { moveOptions, item } = this.props
    let { groups } = moveOptions
    if (moveOptions.excludeCurrent && item.groupId) {
      groups = groups.filter(group => group.id !== item.groupId)
    }
    return (
      <div>
        {this.renderSelect({
          label: I18n.t('Group Select'),
          className: 'move-select__group',
          onChange: this.selectGroup,
          options: groups.map(group =>
            <option key={group.id} value={group.id}>{group.title}</option>)
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
        {this.renderSelect({
          label: I18n.t('Position Select'),
          className: 'move-select__position',
          onChange: this.selectPosition,
          options: Object.keys(positions).map((pos) =>
            <option key={pos} value={pos}>{positions[pos].label}</option>)
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
    const filteredItems = items.filter(item => item.id !== this.props.item.id)
    return this.renderSelect({
      label: I18n.t('Item Select'),
      className: 'move-select__sibling',
      onChange: this.selectSibling,
      options: filteredItems.map((item, index) =>
        <option key={item.id} value={index}>{item.title}</option>)
    })
  }

  render () {
    const { siblings, groups } = this.props.moveOptions
    return (
      <div className="move-select">
        <Typography paragraphMargin="large 0" weight="bold">{I18n.t('Place "%{title}"', { title: this.props.item.title })}</Typography>
        {groups
          ? this.renderSelectGroup()
          : this.renderSelectPosition(siblings)}
        {this.isDoneSelecting() && (
          <Container textAlign="center" display="block">
            <hr />
            <Button variant="primary" onClick={this.submitSelection}>{I18n.t('Done')}</Button>
          </Container>
        )}
      </div>
    )
  }
}
