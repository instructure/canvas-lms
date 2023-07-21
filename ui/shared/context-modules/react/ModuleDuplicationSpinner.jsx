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

import {useScope as useI18nScope} from '@canvas/i18n'

import React from 'react'
import {Grid} from '@instructure/ui-grid'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'

const I18n = useI18nScope('modules')

export default function ModuleDuplicationSpinner(_props) {
  return (
    <Grid startAt="medium" vAlign="middle" rowSpacing="none" colSpacing="none">
      <Grid.Row vAlign="middle" rowSpacing="none">
        <Grid.Col hAlign="center" textAlign="center">
          <Spinner renderTitle={I18n.t('Duplicating Module')} />
        </Grid.Col>
      </Grid.Row>
      <Grid.Row>
        <Grid.Col hAlign="center" textAlign="center">
          <Text>{I18n.t('Duplicating Module...')}</Text>
        </Grid.Col>
      </Grid.Row>
    </Grid>
  )
}
