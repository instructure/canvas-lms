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

import {colors} from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {IconEyeLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('rubrics-form-footer')

type RubricFormFooterProps = {
  assignmentId?: string
  hasRubricAssociations: boolean
  rubricId?: string
  formValid: boolean
  savePending: boolean
  handleCancelButton: () => void
  handlePreviewRubric: () => void
  handleSaveAsDraft: () => void
  handleSave: () => void
}
export const RubricFormFooter = ({
  assignmentId,
  hasRubricAssociations,
  rubricId,
  savePending,
  handleCancelButton,
  handlePreviewRubric,
  handleSaveAsDraft,
  handleSave,
  formValid,
}: RubricFormFooterProps) => {
  return (
    <div id="enhanced-rubric-builder-footer" style={{backgroundColor: colors.contrasts.white1010}}>
      <View
        as="div"
        margin="small large"
        themeOverride={{marginLarge: '48px', marginSmall: '12px'}}
      >
        <Flex justifyItems="end">
          <Flex.Item margin="0 medium 0 0">
            <Button onClick={handleCancelButton} data-testid="cancel-rubric-save-button">
              {I18n.t('Cancel')}
            </Button>

            {!hasRubricAssociations && !assignmentId && (
              <Button
                margin="0 0 0 small"
                disabled={savePending || !formValid}
                onClick={handleSaveAsDraft}
                data-testid="save-as-draft-button"
              >
                {I18n.t('Save as Draft')}
              </Button>
            )}

            <Button
              margin="0 0 0 small"
              color="primary"
              onClick={handleSave}
              disabled={savePending || !formValid}
              data-testid="save-rubric-button"
            >
              {rubricId ? I18n.t('Save Rubric') : I18n.t('Create Rubric')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <View
              as="div"
              padding="0 0 0 medium"
              borderWidth="none none none medium"
              height="2.375rem"
            >
              <Link
                as="button"
                data-testid="preview-rubric-button"
                isWithinText={false}
                margin="x-small 0 0 0"
                onClick={() => handlePreviewRubric()}
              >
                <IconEyeLine /> {I18n.t('Preview Rubric')}
              </Link>
            </View>
          </Flex.Item>
        </Flex>
      </View>
    </div>
  )
}
