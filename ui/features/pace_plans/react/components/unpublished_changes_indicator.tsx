/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {CondensedButton} from '@instructure/ui-buttons'
// @ts-ignore: TS doesn't understand i18n scoped imports
import I18n from 'i18n!unpublished_changes_button_props'
import React from 'react'
import {getUnpublishedChangeCount} from '../reducers/pace_plans'
import {StoreState} from '../types'
import {connect} from 'react-redux'

type StateProps = {
  changeCount: number
}

export type UnpublishedChangesIndicatorProps = StateProps & {
  onClick?: () => void
  margin?: any // type from CondensedButtonProps; passed through
}

const text = (changeCount: number) => {
  if (changeCount < 0) throw Error(`changeCount cannot be negative (${changeCount})`)
  if (changeCount === 0) return I18n.t('All changes published')

  return I18n.t(
    {
      one: '%{count} unpublished change',
      other: '%{count} unpublished changes'
    },
    {count: changeCount}
  )
}

export const UnpublishedChangesIndicator = ({
  changeCount,
  onClick,
  margin
}: UnpublishedChangesIndicatorProps) =>
  changeCount ? (
    <CondensedButton onClick={onClick} margin={margin}>
      {text(changeCount)}
    </CondensedButton>
  ) : (
    <span>{text(changeCount)}</span>
  )

const mapStateToProps = (state: StoreState) => ({
  changeCount: getUnpublishedChangeCount(state)
})

export default connect(mapStateToProps)(UnpublishedChangesIndicator)
