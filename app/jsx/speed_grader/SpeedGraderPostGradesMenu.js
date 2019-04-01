/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool, func} from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconEye from '@instructure/ui-icons/lib/Line/IconEye'
import IconOff from '@instructure/ui-icons/lib/Line/IconOff'
import Menu, {MenuItem} from '@instructure/ui-menu/lib/components/Menu'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import I18n from 'i18n!gradebook'

export default function SpeedGraderPostGradesMenu(props) {
  const menuTrigger = (
    <Button variant="icon-inverse" icon={props.allowPostingGrades ? IconOff : IconEye}>
      <ScreenReaderContent>{I18n.t('Post and Hide Grades')}</ScreenReaderContent>
    </Button>
  )

  return (
    <Menu placement="bottom end" trigger={menuTrigger}>
      {props.allowPostingGrades ? (
        <MenuItem name="postGrades" onSelect={props.onPostGrades}>
          <Text>{I18n.t('Post Grades')}</Text>
        </MenuItem>
      ) : (
        <MenuItem name="postGrades" disabled>
          <Text>{I18n.t('All Grades Posted')}</Text>
        </MenuItem>
      )}

      {props.allowHidingGrades ? (
        <MenuItem name="hideGrades" onSelect={props.onHideGrades}>
          <Text>{I18n.t('Hide Grades')}</Text>
        </MenuItem>
      ) : (
        <MenuItem name="hideGrades" disabled>
          <Text>{I18n.t('All Grades Hidden')}</Text>
        </MenuItem>
      )}
    </Menu>
  )
}

SpeedGraderPostGradesMenu.propTypes = {
  allowHidingGrades: bool.isRequired,
  allowPostingGrades: bool.isRequired,
  onHideGrades: func.isRequired,
  onPostGrades: func.isRequired
}
