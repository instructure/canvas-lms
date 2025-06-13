/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

const I18n = createI18nScope('rubrics-criterion-modal')

type CriterionModalFooterProps = {
  savingCriterion: boolean
  handleDismiss: () => void
  saveChanges: () => void
}
export const CriterionModalFooter = ({
  savingCriterion,
  handleDismiss,
  saveChanges,
}: CriterionModalFooterProps) => {
  return (
    <Flex width="100%">
      <Flex.Item>
        <Button
          margin="0 x-small 0 0"
          onClick={handleDismiss}
          data-testid="rubric-criterion-cancel"
        >
          {I18n.t('Cancel')}
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button
          color="primary"
          type="submit"
          disabled={savingCriterion}
          onClick={() => saveChanges()}
          data-testid="rubric-criterion-save"
        >
          {I18n.t('Save Criterion')}
        </Button>
      </Flex.Item>
    </Flex>
  )
}
