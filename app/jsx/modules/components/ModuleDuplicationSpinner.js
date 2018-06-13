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

import I18n from 'i18n!modules'

import React from 'react'
import Grid, {GridRow, GridCol} from '@instructure/ui-layout/lib/components/Grid/'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Text from '@instructure/ui-elements/lib/components/Text'

export default function ModuleDuplicationSpinner(_props) {
  return (
    <Grid startAt="medium" vAlign="middle" rowSpacing="none" colSpacing="none">
      <GridRow vAlign="middle" rowSpacing="none">
        <GridCol hAlign='center' textAlign='center'>
          <Spinner title={I18n.t('Duplicating Module')}/>
        </GridCol>
      </GridRow>
      <GridRow>
        <GridCol hAlign='center' textAlign='center'>
          <Text>
            {I18n.t('Duplicating Module...')}
          </Text>
        </GridCol>
      </GridRow>
    </Grid>
  )
}
