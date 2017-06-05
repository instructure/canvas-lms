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

import PresentationContent from 'instructure-ui/lib/components/PresentationContent'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import IconArrowOpenRightSolid from 'instructure-icons/lib/Solid/IconArrowOpenRightSolid'
import IconArrowOpenDownSolid from 'instructure-icons/lib/Solid/IconArrowOpenDownSolid'
import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'
import Grid, { GridRow, GridCol } from 'instructure-ui/lib/components/Grid'

import { IconLock, IconUnlock } from './BlueprintLocks'
import LockCheckList from './LockCheckList'

import propTypes from '../propTypes'
import {formatLockObject} from '../LockItemFormat'
import {itemTypeLabelPlurals} from '../labels'


export default class ExpandableLockOptions extends React.Component {
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
          <Typography size="medium" ><Icon /></Typography>
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
              <GridCol width={1}>
                {this.renderIndicatorIcon()}
              </GridCol>
              <GridCol width={2}>
                <PresentationContent>
                  <div className="bcs_tab-text" >
                    <Typography size="small" weight="normal">{itemTypeLabelPlurals[this.props.objectType]}</Typography>
                  </div>
                </PresentationContent>
              </GridCol>
              <GridCol width={1}>
                <PresentationContent>
                  {this.renderLockIcon()}
                </PresentationContent>
              </GridCol>
              <GridCol width={8}>
                <PresentationContent>
                  <div className="bcs_tab-text" >
                    <Typography size="small" weight="normal" >{formatLockObject(this.state.locks)}</Typography>
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
