/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import I18n from 'i18n!HelpTray'
import React from 'react'
import {bool, array, func, string} from 'prop-types'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import HelpDialog from '../HelpDialog/index'
import ReleaseNotesList from '../ReleaseNotesList'

export default function HelpTray({
  trayTitle,
  closeTray,
  links,
  hasLoaded,
  showNotes,
  badgeDisabled,
  setBadgeDisabled
}) {
  return (
    <View as="div" padding="medium" id="help_tray">
      <Heading level="h3" as="h2">
        {trayTitle}
      </Heading>
      <hr role="presentation" />
      <HelpDialog links={links} hasLoaded={hasLoaded} onFormSubmit={closeTray} />
      {showNotes ? (
        <ReleaseNotesList badgeDisabled={badgeDisabled} setBadgeDisabled={setBadgeDisabled} />
      ) : null}
    </View>
  )
}

HelpTray.propTypes = {
  trayTitle: string,
  closeTray: func.isRequired,
  links: array,
  hasLoaded: bool,
  showNotes: bool,
  badgeDisabled: bool,
  setBadgeDisabled: func
}

HelpTray.defaultProps = {
  get trayTitle() {
    return I18n.t('Help')
  },
  hasLoaded: false,
  links: []
}
