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

import React, {useCallback} from 'react'

import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {type PageSection} from './types'

type PageSectionsProps = {
  selectedSections: PageSection[]
  onSelectSections: (sections: PageSection[]) => void
}

const PageSections = ({selectedSections, onSelectSections}: PageSectionsProps) => {
  const handleChangeSelections = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const {checked, value} = e.target

      const newSelectedSections = checked
        ? [...selectedSections, value as PageSection]
        : selectedSections.filter((section: PageSection) => section !== value)

      onSelectSections(newSelectedSections)
    },
    [onSelectSections, selectedSections]
  )

  return (
    <Flex as="div" direction="column" alignItems="center" gap="small">
      <Heading level="h3">Select Page Sections</Heading>
      <View as="div" maxWidth="400px" textAlign="center">
        <Text as="p">
          Preload your page with section placeholders. You will be able to edit, delete, or add more
          sections later.
        </Text>
      </View>
      <Flex direction="row" alignItems="center" gap="medium">
        <Flex.Item textAlign="start">
          <FormFieldGroup layout="stacked" description="Standard">
            <Checkbox
              label="Hero image with text"
              value="heroWithText"
              checked={selectedSections.includes('heroWithText')}
              onChange={handleChangeSelections}
            />
            <Checkbox
              label="Navigation"
              value="navigation"
              checked={selectedSections.includes('navigation')}
              onChange={handleChangeSelections}
            />
            <Checkbox
              label="About (Intro)"
              value="about"
              checked={selectedSections.includes('about')}
              onChange={handleChangeSelections}
            />
            <Checkbox
              label="Highlights or services"
              value="resources"
              checked={selectedSections.includes('resources')}
              onChange={handleChangeSelections}
            />
            <Checkbox
              label="Footer"
              value="footer"
              checked={selectedSections.includes('footer')}
              onChange={handleChangeSelections}
            />
          </FormFieldGroup>
        </Flex.Item>
        <Flex.Item textAlign="start">
          <FormFieldGroup description="Canvas" layout="stacked">
            <Checkbox
              label="Quiz question"
              value="question"
              checked={selectedSections.includes('question')}
              onChange={handleChangeSelections}
            />
            <Checkbox
              label="Announcement"
              value="announcement"
              checked={selectedSections.includes('announcement')}
              onChange={handleChangeSelections}
            />
            <Checkbox
              label="Discussion topic"
              value="discussion"
              checked={selectedSections.includes('discussion')}
              onChange={handleChangeSelections}
              disabled={true}
            />
            <Checkbox
              label="Assignment"
              value="assignment"
              checked={selectedSections.includes('discussion')}
              onChange={handleChangeSelections}
              disabled={true}
            />
            <Checkbox
              label="Module"
              value="module"
              checked={selectedSections.includes('module')}
              onChange={handleChangeSelections}
              disabled={true}
            />
          </FormFieldGroup>
        </Flex.Item>
      </Flex>
    </Flex>
  )
}

export {PageSections}
