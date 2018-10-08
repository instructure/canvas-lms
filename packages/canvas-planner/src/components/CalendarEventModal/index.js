/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react';
import {bool, func, shape, string} from 'prop-types';
import { momentObj } from 'react-moment-proptypes';

import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton';
import Heading from '@instructure/ui-elements/lib/components/Heading';
import Link from '@instructure/ui-elements/lib/components/Link';
import List, {ListItem} from '@instructure/ui-elements/lib/components/List'
import Modal, {ModalHeader, ModalBody} from '@instructure/ui-overlays/lib/components/Modal';
import Text from '@instructure/ui-elements/lib/components/Text';
import View from '@instructure/ui-layout/lib/components/View';

import formatMessage from '../../format-message';
import { dateString, dateTimeString, dateRangeString } from '../../utilities/dateUtils';
import { convertApiUserContent } from '../../utilities/contentUtils';
import { userShape } from '../plannerPropTypes';

export default class CalendarEventModal extends React.Component {
  static propTypes = {
    open: bool.isRequired,
    requestClose: func.isRequired,
    title: string.isRequired,
    html_url: string.isRequired,
    courseName: string,
    currentUser: shape(userShape),
    location: string,
    address: string,
    details: string,
    startTime: momentObj.isRequired,
    endTime: momentObj,
    allDay: bool.isRequired,
    timeZone: string.isRequired,
  }

  renderRow (firstColumnContent, secondColumnContent) {
    return <ListItem>
      <Text weight="bold">{firstColumnContent}</Text>
      <View margin="0 0 0 x-small">
        <Text>{secondColumnContent}</Text>
      </View>
    </ListItem>;
  }

  renderTimeString () {
    const {startTime, endTime, timeZone} = this.props;
    if (this.props.allDay) {
      return dateString(startTime, timeZone);
    } else if (endTime && !startTime.isSame(endTime)) {
      return dateRangeString(startTime, endTime, timeZone);
    } else {
      return dateTimeString(startTime, timeZone);
    }
  }

  renderDateTimeRow () {
    return this.renderRow(formatMessage('Date & Time:'), this.renderTimeString());
  }

  renderCalendarRow () {
    const calendarName = this.props.courseName || this.props.currentUser.displayName;
    return this.renderRow(formatMessage('Calendar:'), calendarName);
  }

  renderLocationRow () {
    if (this.props.location) {
      return this.renderRow(formatMessage('Location:'), this.props.location);
    }
  }

  renderAddressRow () {
    if (this.props.address) {
      return this.renderRow(formatMessage('Address:'), this.props.address);
    }
  }

  renderDetails () {
    if (this.props.details) {
      const convertedHtml = convertApiUserContent(this.props.details);
      return <ListItem margin="large 0 0 0">
        <Text weight="bold">{formatMessage('Details:')}</Text>
        <div dangerouslySetInnerHTML={{__html: convertedHtml}} />
      </ListItem>;
    }
  }

  render () {
    return <Modal
      label="Calendar Event Details"
      size="small"
      open={this.props.open}
      onDismiss={this.props.requestClose}
      shouldCloseOnDocumentClick
    >
      <ModalHeader>
        <Heading><Link href={this.props.html_url}>{this.props.title}</Link></Heading>
        <CloseButton
          placement="end"
          onClick={this.props.requestClose}
        >
          {formatMessage('Close')}
        </CloseButton>
      </ModalHeader>
      <ModalBody padding="medium">
        <List variant="unstyled" itemSpacing="small">
          {this.renderCalendarRow()}
          {this.renderDateTimeRow()}
          {this.renderLocationRow()}
          {this.renderAddressRow()}
          {this.renderDetails()}
        </List>
      </ModalBody>
    </Modal>;
  }
}
