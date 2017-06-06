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
import get from 'lodash/get'

import Grid, { GridRow, GridCol } from 'instructure-ui/lib/components/Grid'
import Typography from 'instructure-ui/lib/components/Typography'
import { IconLock, IconUnlock } from './BlueprintLocks'

import propTypes from '../propTypes'
import {itemTypeLabels, changeTypeLabels} from '../labels'

const UnsyncedChange = (props) => {
  const {asset_type, asset_name, change_type, locked} = props.change

  /* eslint-disable camelcase */
  return (
    <div className="bcs__history-item__change">
      <div className="bcs__history-item__content bcs__unsynced-change__content">
        <div className="bcs__history-item__lock-icon">
          <Typography size="large" color="secondary">{locked ? <IconLock /> : <IconUnlock />}</Typography>
        </div>
        <div className="bcs__history-item__content-grid">
          <Grid colSpacing="none">
            <GridRow>
              <GridCol width={8}>
                <Typography size="small" weight="bold">{asset_name}</Typography>
              </GridCol>
              <GridCol width={2}>
                <Typography size="small" weight="bold">{get(changeTypeLabels, change_type) || change_type}</Typography>
              </GridCol>
              <GridCol width={2}>
                <div style={{textAlign: 'right'}}>
                  <Typography size="small" weight="bold">{get(itemTypeLabels, asset_type) || asset_type}</Typography>
                </div>
              </GridCol>
            </GridRow>
          </Grid>
        </div>
      </div>
    </div>
  )
  /* eslint-disable */
}


UnsyncedChange.propTypes = {
  change: propTypes.unsyncedChange.isRequired
}

export default UnsyncedChange
