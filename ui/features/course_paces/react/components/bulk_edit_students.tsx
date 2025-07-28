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

import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import {BulkEditStudentsTable} from './bulk_edit_students_table'
import {actions} from '../actions/ui'
import {connect} from 'react-redux'
import {PaceContext} from '../types'
import { showFlashAlert } from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('bulk_edit_students')

interface StateProps {
  bulkEditModalOpen: boolean
  selectedBulkStudents: string[]
}

interface DispatchProps {
  readonly openModal: (students: string[]) => void
  readonly closeModal: () => void
  readonly setSelectedPaceContext: typeof actions.setSelectedPaceContext
}

interface PassedProps {
  handleContextSelect: (paceContext: PaceContext, bulkEdit: boolean) => void
}

export const BulkEditStudentPaces = ({
  bulkEditModalOpen,
  selectedBulkStudents,
  openModal,
  closeModal,
  handleContextSelect,
  setSelectedPaceContext
}: StateProps & DispatchProps & PassedProps) => {

  const handleBulkEditClick = () => {
    closeModal()
    const selectedStudentsString = selectedBulkStudents.join(",")

    const paceContext = {
      name: I18n.t('Bulk Edit'),
      type: "BulkEnrollment",
      item_id: selectedStudentsString,
      associated_section_count: 0,
      associated_student_count: selectedBulkStudents.length,
      applied_pace: null,
      on_pace: null,
    }
    handleContextSelect(paceContext, true)
    setSelectedPaceContext('BulkEnrollment', selectedStudentsString)
    showFlashAlert({
      message: I18n.t('Any changes made to these students pacing will effect all individual student paces.'),
      err: null,
      type: 'warning',
    })
  }

  return (
    <View>
      <Flex justifyItems="end">
        <Button
          color="secondary"
          onClick={() => openModal([])}
          margin="small xx-small 0 0"
          data-testid="bulk-edit-student-paces-button"
        >
          {I18n.t('Bulk Edit Student Paces')}
        </Button>
      </Flex>

      <Modal
        data-testid="bulk-edit-students-modal"
        size="large"
        open={bulkEditModalOpen}
        onDismiss={closeModal}
        label={I18n.t('Bulk Edit Student Paces')}
      >
        <Modal.Body>
          <View>
            <Text size="small" wrap="break-word">
              {I18n.t('Select two or more students to bulk edit course pacing.')}
            </Text>
            <Alert variant="info" margin="small">
              {I18n.t('Only students with default course paces and same enrollment dates can be edited in bulk.')}
            </Alert>
            <BulkEditStudentsTable />
          </View>
        </Modal.Body>
        <Modal.Footer>
          <View>
            <Button color="secondary" onClick={closeModal} margin="0 small 0 0">
              {I18n.t('Cancel')}
            </Button>
            <Button color="primary" onClick={handleBulkEditClick} disabled={selectedBulkStudents.length < 2}>
              {I18n.t('Bulk Edit')}
            </Button>
          </View>
        </Modal.Footer>
      </Modal>
    </View>
  )
}

const mapStateToProps = (state: any): StateProps => ({
  bulkEditModalOpen: state.ui.bulkEditModalOpen,
  selectedBulkStudents: state.ui.selectedBulkStudents,
})

const mapDispatchToProps: DispatchProps = {
  openModal: actions.openBulkEditModal,
  closeModal: actions.closeBulkEditModal,
  setSelectedPaceContext: actions.setSelectedPaceContext
}

// @ts-expect-error
export default connect(mapStateToProps, mapDispatchToProps)(BulkEditStudentPaces)
