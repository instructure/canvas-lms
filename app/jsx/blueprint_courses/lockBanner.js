import I18n from 'i18n!blueprint_courses'
import React, { PropTypes, Component } from 'react'
import { Alert, Typography } from 'instructure-ui'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'

const lockLabels = {
  content: I18n.t('Content'),
  points: I18n.t('Points'),
  settings: I18n.t('Settings'),
  due_dates: I18n.t('Due Dates'),
  availability_dates: I18n.t('Availability Dates'),
}

export default class LockBanner extends Component {
  static propTypes = {
    isLocked: PropTypes.bool.isRequired,
    itemLocks: PropTypes.shape({
      content: PropTypes.bool.isRequired,
      points: PropTypes.bool.isRequired,
      due_dates: PropTypes.bool.isRequired,
      availability_dates: PropTypes.bool.isRequired,
    }).isRequired,
  }

  static setupRootNode () {
    const bannerNode = document.createElement('div')
    bannerNode.id = 'blueprint-lock-banner'
    bannerNode.setAttribute('style', 'margin-bottom: 2em')
    const contentNode = document.querySelector('#content')
    return contentNode.insertBefore(bannerNode, contentNode.firstChild)
  }

  componentDidUpdate (prevProps) {
    if (this.props.isLocked && !prevProps.isLocked) {
      $.screenReaderFlashMessage(I18n.t('%{attributes} locked', { attributes: this.composeLockedList() }))
    }
  }

  composeLockedList () {
    const itemLocks = this.props.itemLocks
    const items = Object.keys(itemLocks)
      .filter(item => itemLocks[item])
      .map(item => lockLabels[item])

    if (items.length > 1) {
      return `${items.slice(0, -1).join(', ')} & ${items.slice(-1)[0]}`
    }

    return items[0]
  }

  render () {
    if (this.props.isLocked) {
      return (
        <Alert>
          <Typography weight="bold" size="small">{I18n.t('Locked:')}&nbsp;</Typography>
          <Typography size="small">{this.composeLockedList()}</Typography>
        </Alert>
      )
    }

    return null
  }
}
