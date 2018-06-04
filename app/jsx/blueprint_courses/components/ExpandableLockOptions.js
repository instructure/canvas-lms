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

import I18n from 'i18n!blueprint_courses'
import React from 'react'
import PropTypes from 'prop-types'
import cx from 'classnames'

import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import IconArrowOpenRightSolid from '@instructure/ui-icons/lib/Solid/IconArrowOpenRight'
import IconArrowOpenDownSolid from '@instructure/ui-icons/lib/Solid/IconArrowOpenDown'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Text from '@instructure/ui-elements/lib/components/Text'
import Grid, { GridRow, GridCol } from '@instructure/ui-layout/lib/components/Grid'

import { IconLock, IconUnlock } from './BlueprintLocks'
import LockCheckList from './LockCheckList'

import propTypes from '../propTypes'
import {formatLockObject} from '../LockItemFormat'
import {itemTypeLabelPlurals} from '../labels'


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
    }
  }

  constructor (props) {
    super(props)
    this.state = {
      open: props.isOpen,
      locks: Object.assign({}, props.locks),
    }
  }

  onChange = (locks) => {
    this.setState({
      locks
    })
  }

  onKeyDown = (e) => {
    if (e.keyCode === 32) {
      this.toggle()
    }
  }

  toggle = () => {
    this.setState({
      open: !this.state.open
    })
  }

  renderIndicatorIcon () {
    const Icon = this.state.open ? IconArrowOpenDownSolid : IconArrowOpenRightSolid
    return (
      <div className="bcs_tab_indicator-icon" onKeyDown={this.onKeyDown}>
        <Button variant="icon" onClick={this.toggle} >
          <Text size="medium" ><Icon /></Text>
          <ScreenReaderContent>
            {`${itemTypeLabelPlurals[this.props.objectType]},
            ${this.state.open ? I18n.t('Expanded') : I18n.t('Collapsed')},
            ${formatLockObject(this.state.locks) ? I18n.t('Locked') : I18n.t('Unlocked')},
            ${formatLockObject(this.state.locks)}`}
          </ScreenReaderContent>
        </Button>
      </div>
    )
  }

// The toggle icon and the title of the tab are in a subgrid because the spacing
// If we don't do a subgrid the space between the toggle icon and the title either cuts the icon
// or renders a large space between the icon and the title
  renderTitle () {
    return (
      <Grid>
        <GridRow>
          <GridCol width={4}>
            {this.renderIndicatorIcon()}
          </GridCol>
          <GridCol width={8}>
            <PresentationContent>
              <div className="bcs_tab-text" >
                <Text size="small" weight="normal">{itemTypeLabelPlurals[this.props.objectType]}</Text>
              </div>
            </PresentationContent>
          </GridCol>
        </GridRow>
      </Grid>
    )
  }

  renderLockIcon () {
    const hasLocks = Object.keys(this.state.locks)
      .reduce((isLocked, lockProp) => isLocked || this.state.locks[lockProp], false)
    const Icon = hasLocks ? <IconLock /> : <IconUnlock />
    return (
      <div className="bcs_tab-icon">
        {Icon}
      </div>
    )
  }

  renderSubList () {
    const viewableClasses = cx({
      'bcs_sub-menu': true,
      'bcs_sub-menu-viewable': this.state.open,
    })
    return (
      <div className={viewableClasses}>
        <LockCheckList
          formName={`[blueprint_restrictions_by_object_type][${this.props.objectType}]`}
          locks={this.state.locks}
          lockableAttributes={this.props.lockableAttributes}
          onChange={this.onChange}
        />
      </div>
    )
  }


  render () {
    return (
      <div className="bcs__object-tab">
        <div onClick={this.toggle}>
          <Grid>
            <GridRow>
              <GridCol width={4}>
                {this.renderTitle()}
              </GridCol>
              <GridCol width={1}>
                <PresentationContent>
                  {this.renderLockIcon()}
                </PresentationContent>
              </GridCol>
              <GridCol width={7}>
                <PresentationContent>
                  <div className="bcs_tab-text" >
                    <Text size="small" weight="normal" >{formatLockObject(this.state.locks)}</Text>
                  </div>
                </PresentationContent>
              </GridCol>
            </GridRow>
          </Grid>
        </div>
        {this.renderSubList()}
      </div>
    )
  }
}
