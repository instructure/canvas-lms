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

import I18n from 'i18n!move_item_tray'
import axios from 'axios'
import React from 'react'
import { string, func, arrayOf } from 'prop-types'
import Tray from '@instructure/ui-overlays/lib/components/Tray'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import View from '@instructure/ui-layout/lib/components/View'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'

import { showFlashError } from '../shared/FlashAlert'
import { itemShape, moveOptionsType } from './propTypes'
import MoveSelect from './MoveSelect'

export default class MoveItemTray extends React.Component {
  static propTypes = {
    title: string,
    items: arrayOf(itemShape).isRequired,
    moveOptions: moveOptionsType.isRequired,
    focusOnExit: func,
    formatSaveUrl: func,
    formatSaveData: func,
    onMoveSuccess: func,
    onExited: func,
  }

  static defaultProps = {
    title: I18n.t('Move To'),
    focusOnExit: () => null,
    formatSaveUrl: () => null,
    formatSaveData: (order) => ({ order: order.join(',') }),
    onExited: () => {},
    onMoveSuccess: () => {},
  }

  state = {
    open: true,
  }

  onExited = () => {
    setTimeout(() => {
      const focusTo = this.props.focusOnExit(this.props.items[0])
      if (focusTo) focusTo.focus()
    })
    if (this.props.onExited) this.props.onExited()
  }

  onMoveSelect = ({ order, itemId, groupId, itemIds }) => {
    const saveUrl = this.props.formatSaveUrl({ itemId, groupId })
    const promise = saveUrl
                  ? axios.post(saveUrl, this.props.formatSaveData(order))
                  : Promise.resolve({ data: order })
    promise.then(res => {
      this.props.onMoveSuccess({ data: res.data, groupId, itemId, itemIds })
      this.close()
    })
    .catch(showFlashError(I18n.t('Move Item Failed')))
  }

  open = () => {
    this.setState({ open: true })
  }

  close = () => {
    this.setState({ open: false })
  }

  render () {
    return (
      <Tray
        label={this.props.title}
        open={this.state.open}
        onDismiss={this.close}
        onExited={this.onExited}
        placement="end"
        closeButtonVariant="icon"
        shouldContainFocus
      >
        <CloseButton placement="start" onClick={this.close}>
          {I18n.t('close move tray')}
        </CloseButton>
        <Heading margin="small xx-large" level="h4" as="h2">
          {this.props.title}
        </Heading>
        <View display="block" padding="medium medium large">
          <MoveSelect
            items={this.props.items}
            moveOptions={this.props.moveOptions}
            onSelect={this.onMoveSelect}
            onClose={this.close}
          />
        </View>
      </Tray>
    )
  }
}
