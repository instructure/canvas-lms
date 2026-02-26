/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconDragHandleLine, IconEditLine, IconOutcomesLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('rubrics-criteria-new-row')

type NewCriteriaRowProps = {
  isCompact: boolean
  rowIndex: number
  onEditCriterion: () => void
  onAddOutcome: () => void
}

export const NewCriteriaRow = ({
  isCompact,
  rowIndex,
  onEditCriterion,
  onAddOutcome,
}: NewCriteriaRowProps) => {
  return (
    <tr>
      {!isCompact && (
        <td className="criterion-cell criterion-cell--drag">
          <IconDragHandleLine color="secondary" />
        </td>
      )}
      <td className="criterion-cell criterion-cell--index">
        <Text weight="bold">{rowIndex}.</Text>
      </td>
      <td colSpan={2} className="criterion-cell">
        <Flex direction="row" gap="small" wrap="wrap">
          <Flex.Item>
            <Button
              renderIcon={<IconEditLine />}
              onClick={onEditCriterion}
              data-testid="add-criterion-button"
            >
              {I18n.t('Draft New Criterion')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button
              id="create-from-outcome"
              renderIcon={<IconOutcomesLine />}
              onClick={onAddOutcome}
              data-testid="create-from-outcome-button"
            >
              {I18n.t('Create From Outcome')}
            </Button>
          </Flex.Item>
        </Flex>
      </td>
    </tr>
  )
}
