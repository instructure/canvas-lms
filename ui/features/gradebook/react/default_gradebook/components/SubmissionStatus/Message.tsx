// @ts-nocheck
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
import {Grid} from '@instructure/ui-grid'
import {Text} from '@instructure/ui-text'
import {IconInfoLine, IconWarningLine} from '@instructure/ui-icons'

const VARIANT_MAP = {
  info: {color: 'primary', Icon: IconInfoLine},
  warning: {color: 'danger', Icon: IconWarningLine},
}

const Message = ({message, variant}) => {
  const {Icon, color} = VARIANT_MAP[variant]
  return (
    <Grid>
      <Grid.Row vAlign="middle" hAlign="start" colSpacing="small">
        <Grid.Col width="auto" textAlign="start">
          <Text color={color}>
            <Icon style={{display: 'block'}} />
          </Text>
        </Grid.Col>
        <Grid.Col>
          <Text color={color} size="small">
            {message}
          </Text>
        </Grid.Col>
      </Grid.Row>
    </Grid>
  )
}

Message.propTypes = {
  message: string.isRequired,
  variant: oneOf(['info', 'warning']).isRequired,
}

export default Message
