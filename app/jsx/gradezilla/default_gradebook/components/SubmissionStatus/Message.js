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

import React from 'react'
import {oneOf, string} from 'prop-types'
import Grid, { GridCol, GridRow } from '@instructure/ui-core/lib/components/Grid'
import Text from '@instructure/ui-core/lib/components/Text'
import IconInfoLine from 'instructure-icons/lib/Line/IconInfoLine'
import IconWarningLine from 'instructure-icons/lib/Line/IconWarningLine'

const VARIANT_MAP = {
  info: {color: 'primary', Icon: IconInfoLine},
  warning: {color: 'warning', Icon: IconWarningLine}
}

const Message = ({message, variant}) => {
  const { Icon, color } = VARIANT_MAP[variant]
  return (
    <Grid>
      <GridRow
        vAlign="middle"
        hAlign="start"
        colSpacing="small"
      >
        <GridCol width="auto" textAlign="start">
          <Text color={color}>
            <Icon title={message} style={{display: 'block'}} />
          </Text>
        </GridCol>
        <GridCol>
          <Text color={color} size="small">
            {message}
          </Text>
        </GridCol>
      </GridRow>
    </Grid>
  )
}

Message.propTypes = {
  message: string.isRequired,
  variant: oneOf(['info', 'warning']).isRequired
}

export default Message
