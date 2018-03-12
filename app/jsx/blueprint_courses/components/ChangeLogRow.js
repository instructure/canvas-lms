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
import React, { Component } from 'react'
import {string, bool, node} from 'prop-types'
import cx from 'classnames'
import shortId from '../../shared/shortid'

import Grid, { GridRow, GridCol } from '@instructure/ui-core/lib/components/Grid'
import Text from '@instructure/ui-core/lib/components/Text'
import { IconLock, IconUnlock } from './BlueprintLocks'

import propTypes from '../propTypes'
import { itemTypeLabels, changeTypeLabels } from '../labels'

export default class ChangeLogRow extends Component {
  static propTypes = {
    col1: string.isRequired,
    col2: string.isRequired,
    col3: string.isRequired,
    col4: string.isRequired,
    isHeading: bool,
    children: node,
  }

  static defaultProps = {
    isHeading: false,
    children: null,
  }

  colIds = [shortId(), shortId(), shortId(), shortId()]

  renderText = text => <Text size="small" weight={this.props.isHeading ? 'bold' : 'normal'}>{text}</Text>

  renderRow () {
    const { col1, col2, col3, col4, isHeading } = this.props
    const cellRole = isHeading ? 'columnheader' : 'gridcell'
    return (
      <Grid colSpacing="none">
        <GridRow>
          <GridCol width={6}><span id={this.colIds[0]} role={cellRole}>{this.renderText(col1)}</span></GridCol>
          <GridCol width={2}><span id={this.colIds[1]} role={cellRole}>{this.renderText(col2)}</span></GridCol>
          <GridCol width={3}><span id={this.colIds[2]} role={cellRole}>{this.renderText(col3)}</span></GridCol>
          <GridCol width={1}><span id={this.colIds[3]} role={cellRole}>{this.renderText(col4)}</span></GridCol>
        </GridRow>
      </Grid>
    )
  }

  render () {
    const classes = cx({
      'bcs__history-item__change': true,
      'bcs__history-item__change-log-row': true,
      'bcs__history-item__change-log-row__heading': this.props.isHeading,
    })

    return (
      <div className={classes} role="row" aria-owns={this.colIds.join(' ')}>
        <div className="bcs__history-item__content">
          {this.props.children}
          <div className="bcs__history-item__content-grid">
            {this.renderRow()}
          </div>
        </div>
      </div>
    )
  }
}

export const ChangeRow = ({ change }) => (
  <ChangeLogRow
    col1={change.asset_name}
    col2={itemTypeLabels[change.asset_type]}
    col3={changeTypeLabels[change.change_type]}
    col4={change.exceptions && change.exceptions.length ? I18n.t('No') : I18n.t('Yes')}
  >
    <div className="bcs__history-item__lock-icon">
      <Text size="large" color="secondary">{change.locked ? <IconLock /> : <IconUnlock />}</Text>
    </div>
  </ChangeLogRow>
)

ChangeRow.propTypes = {
  change: propTypes.migrationChange.isRequired,
}
