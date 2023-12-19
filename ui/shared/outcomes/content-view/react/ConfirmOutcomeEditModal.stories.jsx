/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import ConfirmOutcomeEditModal from './ConfirmOutcomeEditModal'

export default {
  title: 'Examples/Outcomes/ConfirmOutcomeEditModal',
  component: ConfirmOutcomeEditModal,
  args: {
    changed: true,
    assessed: true,
    hasUpdateableRubrics: false,
    modifiedFields: {
      masteryPoints: true,
      scoringMethod: true,
    },
    onConfirm: () => {},
  },
}

// Similar to showConfirmOutcomeEdit but without ReactDOM.render so we don't have to
//  handle unmounting ourselves
function showConfirmOutcomeEdit(props) {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'confirm-outcome-edit-modal-container')
  document.body.appendChild(parent)

  function showConfirmOutcomeEditRef(modal) {
    if (modal) modal.show()
  }

  return <ConfirmOutcomeEditModal {...props} parent={parent} ref={showConfirmOutcomeEditRef} />
}

const Template = args => showConfirmOutcomeEdit(args)

export const Default = Template.bind({})
