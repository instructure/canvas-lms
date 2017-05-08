import I18n from 'i18n!blueprint_settings'
import React, { Component } from 'react'
import cx from 'classnames'

import dig from 'jsx/shared/dig'
import Grid, { GridRow, GridCol } from 'instructure-ui/lib/components/Grid'
import Typography from 'instructure-ui/lib/components/Typography'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import ToggleDetails from 'instructure-ui/lib/components/ToggleDetails'
import IconLockSolid from 'instructure-icons/lib/Solid/IconLockSolid'
import IconUnlockSolid from 'instructure-icons/lib/Solid/IconUnlockSolid'

import propTypes from '../propTypes'

import {itemTypeLabels, changeTypeLabels, exceptionTypeLabels} from '../labels'

class SyncChange extends Component {
  static propTypes = {
    change: propTypes.migrationChange.isRequired,
  }

  constructor (props) {
    super(props)
    this.state = {
      isExpanded: false,
    }
  }

  toggleExpanded = () => {
    this.setState({ isExpanded: !this.state.isExpanded })
  }

  renderText = text => <Typography size="small" weight="bold">{text}</Typography>
  renderSpace = () => <span style={{display: 'inline-block', width: '20px'}} />

  renderExceptionGroup (exType, items) {
    return (
      <li key={exType} className="bcs__history-item__change-exceps__group">
        {this.renderText(exceptionTypeLabels[exType])}
        <ul className="bcs__history-item__change-exceps__courses">
          {items.map(item => (
            <li key={item.course_id}>
              {dig(item, 'term.name') || ''} - {item.name}{this.renderSpace()}{item.sis_course_id}{this.renderSpace()}{item.course_code}
            </li>
          ))}
        </ul>
      </li>
    )
  }

  renderExceptions () {
    const exGroups = this.props.change.exceptions.reduce((groups, ex) => {
      ex.conflicting_changes.forEach((conflict) => {
        groups[conflict] = groups[conflict] || [] // eslint-disable-line
        groups[conflict].push(ex)
      })
      return groups
    }, {})

    return (
      <ul className="bcs__history-item__change-exceps">
        {Object.keys(exGroups)
          .map(groupType => this.renderExceptionGroup(groupType, exGroups[groupType]))}
      </ul>
    )
  }

  render () {
    const { asset_type, asset_name, change_type, exceptions, locked } = this.props.change
    const hasExceptions = exceptions.length > 0
    const classes = cx({
      'bcs__history-item__change': true,
      'bcs__history-item__change__expanded': this.state.isExpanded,
    })

    return (
      <div className={classes} onClick={this.toggleExpanded}>
        <div className="bcs__history-item__content">
          {hasExceptions &&
            <ToggleDetails
              summary={<ScreenReaderContent>{I18n.t('Show exceptions')}</ScreenReaderContent>}
              isExpanded={this.state.isExpanded}
            >
              {this.renderExceptions()}
            </ToggleDetails>}
          <div className="bcs__history-item__lock-icon">
            <Typography size="large" color="secondary">{locked ? <IconLockSolid /> : <IconUnlockSolid />}</Typography>
          </div>
          <div className="bcs__history-item__content-grid">
            <Grid colSpacing="none">
              <GridRow>
                <GridCol width={6}>{this.renderText(asset_name)}</GridCol>
                <GridCol width={2}>{this.renderText(itemTypeLabels[asset_type])}</GridCol>
                <GridCol width={2}>{this.renderText(changeTypeLabels[change_type])}</GridCol>
                <GridCol width={2}>
                  <div style={{textAlign: 'right'}}>
                    {hasExceptions ? (
                      <Typography size="x-small" color="secondary">
                        <span className="pill">
                          {I18n.t({ one: '%{count} exception', other: '%{count} exceptions' }, { count: exceptions.length })}
                        </span>
                      </Typography>
                    ) : this.renderText(I18n.t('Applied'))}
                  </div>
                </GridCol>
              </GridRow>
            </Grid>
          </div>
        </div>
      </div>
    )
  }
}

export default SyncChange
