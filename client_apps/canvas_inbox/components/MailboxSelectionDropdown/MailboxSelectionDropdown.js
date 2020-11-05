/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import PropTypes from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
// import {t} from 'i18n!conversations'
// TODO: replace with frd translation function
const t = str => str

export const mailboxLabels = {
  inbox: () => t('Inbox'),
  unread: () => t('Unread'),
  starred: () => t('Starred'),
  sent: () => t('Sent'),
  archived: () => t('Archived'),
  submission_comments: () => t('Submission Comments')
}

export const MailboxSelectionDropdown = ({...props}) => {
  return (
    <SimpleSelect
      renderLabel={() => <ScreenReaderContent>{t('Mailbox Selection')}</ScreenReaderContent>}
      onChange={(_event, data) => props.onSelect(data.value)}
      value={props.activeMailbox}
      size="small"
    >
      {Object.entries(mailboxLabels).map(([mailbox, translateLabel]) => (
        <SimpleSelect.Option id={mailbox} key={mailbox} value={mailbox}>
          {translateLabel.call()}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
  )
}

MailboxSelectionDropdown.propTypes = {
  /**
   * Behavior when a mailbox is selected
   */
  onSelect: PropTypes.func.isRequired,
  /**
   * Which mailbox to list as selected
   */
  activeMailbox: PropTypes.oneOf(Object.keys(mailboxLabels)).isRequired
}

export default MailboxSelectionDropdown
