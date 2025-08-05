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

import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {ButtonData} from './ButtonBlock'

export type ButtonBlockIndividualButtonSettingsProps = {
  initialButtons: ButtonData[]
  onButtonsChange: (buttons: ButtonData[]) => void
}

export const ButtonBlockIndividualButtonSettings = ({
  initialButtons: initialButtons,
  onButtonsChange,
}: ButtonBlockIndividualButtonSettingsProps) => {
  const addButton = () => {
    const newButton = {
      id: initialButtons.length + 1,
    }
    onButtonsChange([...initialButtons, newButton])
  }
  return (
    <Flex direction="column">
      <Button onClick={addButton}>Add Button</Button>
    </Flex>
  )
}
