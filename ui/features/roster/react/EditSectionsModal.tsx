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

import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'
import SectionSelector, {ExistingSectionEnrollment} from './SectionSelector'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useState} from 'react'

const I18n = createI18nScope('edit_section_view')

interface Props {
  onClose: () => void
  onUpdate: (sections: ExistingSectionEnrollment[]) => Promise<void>
  excludeSections: ExistingSectionEnrollment[]
}

export default function EditSectionsModal(props: Props) {
  const [selectedSections, setSelectedSections] = useState<ExistingSectionEnrollment[]>(
    props.excludeSections,
  )
  const editSectionsTitle = I18n.t('Edit Sections')

  const onUpdate = async () => {
    try {
      await props.onUpdate(selectedSections)
      showFlashSuccess(I18n.t('Section enrollments updated successfully'))
    } catch (error) {
      showFlashError(I18n.t('Failed to update section enrollments'))(error as Error)
    } finally {
      props.onClose()
    }
  }

  return (
    <QueryClientProvider client={queryClient}>
      <Modal label={editSectionsTitle} open={true} shouldCloseOnDocumentClick={false} size="small">
        <Modal.Header>
          <Heading>{editSectionsTitle}</Heading>
          <CloseButton
            data-testid="close-button"
            screenReaderLabel={I18n.t('Close')}
            placement="end"
            onClick={props.onClose}
          />
        </Modal.Header>
        <Modal.Body>
          <Flex gap="inputFields" direction="column">
            <Text>
              {I18n.t(
                'Sections are an additional way to organize users. This can allow you to teach multiple classes from the same course, so that you can have the course content all in one place. Below you can move a user to a different section, or add/remove section enrollments. Users must be in at least one section at all times.',
              )}
            </Text>
            <SectionSelector
              courseId={ENV.current_context?.id}
              selectedSections={selectedSections}
              setSelectedSections={sections => {
                setSelectedSections(sections)
              }}
            />
          </Flex>
        </Modal.Body>
        <Modal.Footer>
          <Flex gap="buttons" justifyItems="end">
            <Button data-testid="cancel-button" onClick={props.onClose}>
              {I18n.t('Cancel')}
            </Button>
            <Button data-testid="save-button" color="primary" onClick={onUpdate}>
              {I18n.t('Save')}
            </Button>
          </Flex>
        </Modal.Footer>
      </Modal>
    </QueryClientProvider>
  )
}
