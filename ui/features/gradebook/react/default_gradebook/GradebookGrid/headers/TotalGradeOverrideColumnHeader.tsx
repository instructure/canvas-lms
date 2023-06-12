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

import React, {PureComponent} from 'react'
import {View} from '@instructure/ui-view'
import {Grid} from '@instructure/ui-grid'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

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
            <Grid.Row>
              <Grid.Col textAlign="center">
                <View className="Gradebook__ColumnHeaderDetail Gradebook__ColumnHeaderDetail--OneLine">
                  <Text fontStyle="normal" size="x-small" weight="bold">
                    {I18n.t('Override')}
                  </Text>
                </View>
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </div>
      </div>
    )
  }
}
