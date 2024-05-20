// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import type {SkillData} from '../types'

interface AddSkillModalProps {
  open: boolean
  onDismiss: () => void
  onAddSkill: (skill: SkillData) => void
}

const AddSkillModal = ({open, onDismiss, onAddSkill}: AddSkillModalProps) => {
  const [skill, setSkill] = useState('')
  const textInputRef = useRef(null)

  useEffect(() => {
    setSkill('')
  }, [open])

  const handleSkillChange = useCallback(
    (_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
      setSkill(value)
    },
    []
  )

  const handleSubmit = useCallback(
    (e: React.UIEvent) => {
      e.preventDefault()
      e.stopPropagation()
      const skillName = (textInputRef.current as HTMLInputElement).value
      if (!skillName.trim()) return
      onAddSkill({name: skillName, verified: false})
    },
    [textInputRef, onAddSkill]
  )

  const handleTextKey = useCallback((e: KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      e.stopPropagation()(
        document.getElementById('add_skill_form') as HTMLFormElement
      )?.requestSubmit()
    }
  }, [])

  const handleSaveClick = useCallback(() => {
    ;(document.getElementById('add_skill_form') as HTMLFormElement)?.requestSubmit()
  }, [])

  useEffect(() => {
    if (textInputRef.current) {
      textInputRef.current.addEventListener('keydown', handleTextKey)
    }
  }, [handleTextKey, textInputRef])

  return (
    <Modal open={open} size="auto" label="Add Skill or Tool" onDismiss={onDismiss}>
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={onDismiss}
          screenReaderLabel="Close"
        />
        <Heading>Add Skill or Tool</Heading>
      </Modal.Header>
      <Modal.Body>
        {/* @ts-expect-error */}
        <form id="add_skill_form" onSubmit={handleSubmit}>
          <View as="div" minWidth="700px">
            <TextInput
              inputRef={(el: HTMLInputElement) => {
                textInputRef.current = el
              }}
              name="skill"
              renderLabel="Skill"
              onChange={handleSkillChange}
              value={skill}
            />
          </View>
        </form>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onDismiss}>Cancel</Button>
        <Tooltip
          renderTip="You must provide skill first"
          on={skill.trim() ? [] : ['click', 'hover', 'focus']}
        >
          {/* @ts-expect-error */}
          <Button color="primary" margin="0 0 0 small" onClick={handleSaveClick}>
            Save
          </Button>
        </Tooltip>
      </Modal.Footer>
    </Modal>
  )
}

export default AddSkillModal
