import React from 'react'

import dig from 'jsx/shared/dig'
import Grid, { GridRow, GridCol } from 'instructure-ui/lib/components/Grid'
import Typography from 'instructure-ui/lib/components/Typography'
import IconLockSolid from 'instructure-icons/lib/Solid/IconLockSolid'
import IconUnlockSolid from 'instructure-icons/lib/Solid/IconUnlockSolid'

import propTypes from '../propTypes'
import {itemTypeLabels, changeTypeLabels} from '../labels'

const UnsynchedChange = (props) => {
  const {asset_type, asset_name, change_type, locked} = props.change

  /* eslint-disable camelcase */
  return (
    <div className="bcs__history-item__change">
      <div className="bcs__history-item__content bcs__unsynched-change__content">
        <div className="bcs__history-item__lock-icon">
          <Typography size="large" color="secondary">{locked ? <IconLockSolid /> : <IconUnlockSolid />}</Typography>
        </div>
        <div className="bcs__history-item__content-grid">
          <Grid colSpacing="none">
            <GridRow>
              <GridCol width={8}>
                <Typography size="small" weight="bold">{asset_name}</Typography>
              </GridCol>
              <GridCol width={2}>
                <Typography size="small" weight="bold">{dig(changeTypeLabels, change_type) || change_type}</Typography>
              </GridCol>
              <GridCol width={2}>
                <div style={{textAlign: 'right'}}>
                  <Typography size="small" weight="bold">{dig(itemTypeLabels, asset_type) || asset_type}</Typography>
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


UnsynchedChange.propTypes = {
  change: propTypes.unsynchedChange.isRequired
}

export default UnsynchedChange
