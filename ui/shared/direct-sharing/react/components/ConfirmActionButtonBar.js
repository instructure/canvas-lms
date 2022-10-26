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
import {bool, string, func} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'

ConfirmActionButtonBar.propTypes = {
  // only buttons with labels will be displayed
  primaryLabel: string,
  primaryDisabled: bool,
  secondaryLabel: string,
  onPrimaryClick: func,
  onSecondaryClick: func,

  padding: string,
}

export default function ConfirmActionButtonBar({
  primaryLabel,
  primaryDisabled,
  secondaryLabel,
  onPrimaryClick,
  onSecondaryClick,
  padding,
}) {
  const primaryButton = !primaryLabel ? null : (
    <Button
      margin="0 0 0 x-small"
      color="primary"
      onClick={onPrimaryClick}
      disabled={primaryDisabled}
    >
      {primaryLabel}
    </Button>
  )

  const secondaryButton = !secondaryLabel ? null : (
    <Button onClick={onSecondaryClick}>{secondaryLabel}</Button>
  )

  return (
    <Flex justifyItems="end" padding={padding}>
      <Flex.Item>
        {secondaryButton}
        {primaryButton}
      </Flex.Item>
    </Flex>
  )
}
