/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React, {useState} from 'react'
import CreateTicketForm from './CreateTicketForm'
import TeacherFeedbackForm from './TeacherFeedbackForm'
import HelpLinks from './HelpLinks'

type Props = {
  onFormSubmit: () => void
}

function HelpDialog({onFormSubmit}: Props) {
  const [view, setView] = useState('links')

  const handleLinkClick = (url: string) => {
    setView(url)
  }

  const handleCancelClick = () => {
    setView('links')
  }

  switch (view) {
    case '#create_ticket':
      return <CreateTicketForm onCancel={handleCancelClick} onSubmit={onFormSubmit} />
    case '#teacher_feedback':
      return <TeacherFeedbackForm onCancel={handleCancelClick} onSubmit={onFormSubmit} />
    default:
      return <HelpLinks onClick={handleLinkClick} />
  }
}

export default HelpDialog
