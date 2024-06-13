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

import React, {useCallback, useState} from 'react'
import {useEditor} from '@craftjs/core'

import {IconArrowStartLine} from '@instructure/ui-icons'
import {CloseButton, Button, CondensedButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Modal} from '@instructure/ui-modal'

import {Step1, type Step1Selection} from './Step1'
import {PageSections} from './PageSections'
import {ColorPalette} from './ColorPalette'
import {FontPairings} from './FontPairings'
import {PageTemplates} from './PageTemplates'
import {buildPageContent} from '../../../utils'
import {type PageSection} from './types'

type NewPageStepperProps = {
  open: boolean
  onDismiss: () => void
}

const NewPageStepper = ({open, onDismiss}: NewPageStepperProps) => {
  const {actions, query} = useEditor()
  const [step, setStep] = useState(0)
  const [startingPoint, setStartingPoint] = useState<Step1Selection>('scratch')
  const [selectedSections, setSelectedSections] = useState<PageSection[]>([])
  const [paletteId, setpaletteId] = useState<string>('palette0')
  const [fontName, setFontName] = useState<string>('font0')

  const handleNextStep = useCallback(() => {
    if (step < 3) {
      setStep(step + 1)
    } else {
      buildPageContent(actions, query, selectedSections, paletteId, fontName)
      onDismiss()
    }
  }, [actions, fontName, onDismiss, paletteId, query, selectedSections, step])

  const handlePrevStep = useCallback(() => {
    setStep(step - 1)
  }, [step])

  const handleSelectStart = useCallback((start: Step1Selection) => {
    setStartingPoint(start)
  }, [])

  const handleSelectSections = useCallback((sections: PageSection[]) => {
    setSelectedSections(sections)
  }, [])

  const handleSelectPalette = useCallback((newpaletteId: string) => {
    setpaletteId(newpaletteId)
  }, [])

  const handleSelectFont = useCallback((newFontName: string) => {
    setFontName(newFontName)
  }, [])

  const renderActiveStep = () => {
    switch (step) {
      case 0:
        return <Step1 onSelect={handleSelectStart} start={startingPoint} />
      case 1:
        if (startingPoint === 'scratch') {
          return (
            <PageSections
              selectedSections={selectedSections}
              onSelectSections={handleSelectSections}
            />
          )
        } else {
          return <PageTemplates />
        }
      case 2:
        return <ColorPalette paletteId={paletteId} onSelectPalette={handleSelectPalette} />
      case 3:
        return <FontPairings fontName={fontName} onSelectFont={handleSelectFont} />
      default:
        throw new Error('Invalid step')
    }
  }

  return (
    <Modal open={open} label="Create a new page" onDismiss={onDismiss}>
      <Modal.Header>
        <Heading>Create a new page</Heading>
        <CloseButton
          data-instui-modal-close-button="true"
          onClick={onDismiss}
          screenReaderLabel="Close"
          placement="end"
          offset="medium"
        />
      </Modal.Header>
      <Modal.Body>
        <View as="div" padding="small" width="660px" height="519px">
          {step > 0 && (
            <CondensedButton
              renderIcon={<IconArrowStartLine />}
              margin="0 0 small"
              onClick={handlePrevStep}
            >
              Back
            </CondensedButton>
          )}
          {renderActiveStep()}
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onDismiss}>
          Cancel
        </Button>
        <Button color="primary" margin="0 0 0 small" onClick={handleNextStep}>
          {step < 3 ? 'Next' : 'Start Creating'}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {NewPageStepper}
