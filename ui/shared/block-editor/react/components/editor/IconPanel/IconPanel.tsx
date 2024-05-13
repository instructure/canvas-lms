/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {SVGIcon} from '@instructure/ui-svg-images'

import icon_alarm from '../../../assets/icons/alarm.svg'
import icon_apple from '../../../assets/icons/apple.svg'
import icon_atom from '../../../assets/icons/atom.svg'
import icon_basketball from '../../../assets/icons/basketball.svg'
import icon_bell from '../../../assets/icons/bell.svg'
import icon_briefcase from '../../../assets/icons/briefcase.svg'
import icon_calculator from '../../../assets/icons/calculator.svg'
import icon_calendar from '../../../assets/icons/calendar.svg'
import icon_clock from '../../../assets/icons/clock.svg'
import icon_cog from '../../../assets/icons/cog.svg'
import icon_communication from '../../../assets/icons/communication.svg'
import icon_conical_flask from '../../../assets/icons/conical flask.svg'
import icon_flask from '../../../assets/icons/flask.svg'
import icon_glasses from '../../../assets/icons/glasses.svg'
import icon_globe from '../../../assets/icons/globe.svg'
import icon_idea from '../../../assets/icons/idea.svg'
import icon_monitor from '../../../assets/icons/monitor.svg'
import icon_note_paper from '../../../assets/icons/note paper.svg'
import icon_notebook from '../../../assets/icons/notebook.svg'
import icon_notes from '../../../assets/icons/notes.svg'
import icon_pencil from '../../../assets/icons/pencil.svg'
import icon_resume from '../../../assets/icons/resume.svg'
import icon_ruler from '../../../assets/icons/ruler.svg'
import icon_schedule from '../../../assets/icons/schedule.svg'
import icon_test_tube from '../../../assets/icons/test tube.svg'

const IconPanel = ({isOpen, onClose, onSelect}) => {
  const icons = [
    icon_alarm,
    icon_apple,
    icon_atom,
    icon_basketball,
    icon_bell,
    icon_briefcase,
    icon_calculator,
    icon_calendar,
    icon_clock,
    icon_cog,
    icon_communication,
    icon_conical_flask,
    icon_flask,
    icon_glasses,
    icon_globe,
    icon_idea,
    icon_monitor,
    icon_note_paper,
    icon_notebook,
    icon_notes,
    icon_pencil,
    icon_resume,
    icon_ruler,
    icon_schedule,
    icon_test_tube,
  ]

  return (
    <Modal open={isOpen} onDismiss={onClose} size="fullscreen" label="Icon Panel">
      <Modal.Header>
        <Heading level="h2">Select an Icon</Heading>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body padding="medium">
        <div style={{display: 'flex', flexWrap: 'wrap'}}>
          {icons.map((icon, index) => (
            <SVGIcon key={icon} src={icon} size="small" />
          ))}
        </div>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Button color="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button color="primary" onClick={onSelect}>
            Select
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
