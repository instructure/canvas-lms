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

import React, {PureComponent} from 'react'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!gradebook'

export default class TotalGradeOverrideColumnHeader extends PureComponent {
  /*
   * This is a required part of the Column Header API for hooking focus updates
   * into location changes within the grid.
   */
  focusAtStart() {}

  /*
   * This is a required part of the Column Header API for hooking focus updates
   * into location changes within the grid.
   */
  focusAtEnd() {}

  /*
   * This is a required part of the Column Header API for preempting keydown
   * event handlers when the column header employs behavior for keydown events.
   */
  handleKeyDown(_event) {}

  render() {
    return (
      <div className="Gradebook__ColumnHeaderContent">
        <div style={{flex: 1, minWidth: '1px'}}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <GridRow>
              <GridCol textAlign="center" width="auto">
                <div className="Gradebook__ColumnHeaderIndicators" />
              </GridCol>

              <GridCol textAlign="center">
                <View className="Gradebook__ColumnHeaderDetail">
                  <Text fontStyle="normal" size="x-small" weight="bold">
                    {I18n.t('Override')}
                  </Text>
                </View>
              </GridCol>

              <GridCol textAlign="center" width="auto">
                <div className="Gradebook__ColumnHeaderAction" />
              </GridCol>
            </GridRow>
          </Grid>
        </div>
      </div>
    )
  }
}
