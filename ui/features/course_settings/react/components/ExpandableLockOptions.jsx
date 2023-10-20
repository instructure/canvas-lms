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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import cx from 'classnames'

import {PresentationContent} from '@instructure/ui-a11y-content'
import {IconArrowOpenEndSolid, IconArrowOpenDownSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Grid} from '@instructure/ui-grid'

import {IconLock, IconUnlock} from '@canvas/blueprint-courses/react/components/BlueprintLocks'
import LockCheckList from './LockCheckList'

import propTypes from '@canvas/blueprint-courses/react/propTypes'
import {formatLockObject} from '@canvas/blueprint-courses/react/LockItemFormat'
import {itemTypeLabelPlurals} from '@canvas/blueprint-courses/react/labels'

const I18n = useI18nScope('blueprint_coursesExpandableLockOptions')

// ExpandableLockOptions is a single expandable tab that has a list of checkboxes as children
// The tab has the toggle icon, the title of the tab, the lock icon that indicates whether the
// children are checked or not, and the list of checked children
// This is used in Blueprint Lock Options as the granular lock

export default class ExpandableLockOptions extends React.Component {
  // objectType is the Title of the tab
  // locks are the values of the children (whether they are checked or not)
  // isOpen determines whether the tab is expanded or not
  // lockableAttributes are the list of items that could be locked (the list of children)
  static propTypes = {
    objectType: PropTypes.string.isRequired,
    locks: propTypes.itemLocks,
    isOpen: PropTypes.bool,
    lockableAttributes: propTypes.lockableAttributeList.isRequired,
  }

  static defaultProps = {
    isOpen: false,
    locks: {
      content: false,
      points: false,
      due_dates: false,
      availability_dates: false,
    },
  }

  constructor(props) {
    super(props)
    this.state = {
      open: props.isOpen,
      locks: {...props.locks},
    }
  }

  onChange = locks => {
    this.setState({
      locks,
    })
  }

  onKeyDown = e => {
    if (e.keyCode === 32) {
      this.toggle()
    }
  }

  toggle = () => {
    this.setState({
      open: !this.state.open,
    })
  }

  renderIndicatorIcon() {
    const Icon = this.state.open ? IconArrowOpenDownSolid : IconArrowOpenEndSolid
    return (
      // eslint-disable-next-line jsx-a11y/no-static-element-interactions
      <div className="bcs_tab_indicator-icon" onKeyDown={this.onKeyDown}>
        <IconButton
          withBorder={false}
          withBackground={false}
          screenReaderLabel={`${itemTypeLabelPlurals[this.props.objectType]},
            ${this.state.open ? I18n.t('Expanded') : I18n.t('Collapsed')},
            ${formatLockObject(this.state.locks) ? I18n.t('Locked') : I18n.t('Unlocked')},
            ${formatLockObject(this.state.locks)}`}
          renderIcon={
            <Text size="medium">
              <Icon />
            </Text>
          }
        />
      </div>
    )
  }

  // The toggle icon and the title of the tab are in a subgrid because the spacing
  // If we don't do a subgrid the space between the toggle icon and the title either cuts the icon
  // or renders a large space between the icon and the title
  renderTitle() {
    return (
      <Grid>
        <Grid.Row>
          <Grid.Col width={4}>{this.renderIndicatorIcon()}</Grid.Col>
          <Grid.Col width={8}>
            <PresentationContent>
              <div className="bcs_tab-text">
                <Text size="small" weight="normal">
                  {itemTypeLabelPlurals[this.props.objectType]}
                </Text>
              </div>
            </PresentationContent>
          </Grid.Col>
        </Grid.Row>
      </Grid>
    )
  }

  renderLockIcon() {
    const hasLocks = Object.keys(this.state.locks).reduce(
      (isLocked, lockProp) => isLocked || this.state.locks[lockProp],
      false
    )
    const Icon = hasLocks ? (
      <IconLock data-testid="lock-icon" />
    ) : (
      <IconUnlock data-testid="unlock-icon" />
    )
    return <div className="bcs_tab-icon">{Icon}</div>
  }

  renderSubList() {
    const viewableClasses = cx({
      'bcs_sub-menu': true,
      'bcs_sub-menu-viewable': this.state.open,
    })
    return (
      <div className={viewableClasses} data-testid="sub-list">
        <LockCheckList
          formName={`[blueprint_restrictions_by_object_type][${this.props.objectType}]`}
          locks={this.state.locks}
          lockableAttributes={this.props.lockableAttributes}
          onChange={this.onChange}
        />
      </div>
    )
  }

  render() {
    return (
      <div className="bcs__object-tab">
        {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events,jsx-a11y/no-static-element-interactions */}
        <div onClick={this.toggle} data-testid="toggle">
          <Grid>
            <Grid.Row>
              <Grid.Col width={4}>{this.renderTitle()}</Grid.Col>
              <Grid.Col width={1}>
                <PresentationContent>{this.renderLockIcon()}</PresentationContent>
              </Grid.Col>
              <Grid.Col width={7}>
                <PresentationContent>
                  <div className="bcs_tab-text">
                    <Text size="small" weight="normal">
                      {formatLockObject(this.state.locks)}
                    </Text>
                  </div>
                </PresentationContent>
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </div>
        {this.renderSubList()}
      </div>
    )
  }
}
