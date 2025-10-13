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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {NutritionFacts} from '../NutritionFacts'
import {NutritionFactsExternalRoot} from '../types'

injectGlobalAlertContainers()

describe('Nutrition facts', () => {
  const defaultProps: NutritionFactsExternalRoot = {
    id: 'canvasCourseTranslation',
    name: 'Discussions Translation',
    sha256: 'stub-hash',
    lastUpdated: '1234567890',
    nutritionFacts: {
      name: 'Discussions Translation',
      description: 'Test description',
      data: [
        {
          blockTitle: 'Model & Data',
          segmentData: [
            {
              segmentTitle: 'Base Model',
              description:
                'The foundational AI on which further training and customizations are built.',
              value: 'Haiku 3.0.0',
              valueDescription: 'Internal platform routed model',
            },
            {
              segmentTitle: 'Trained with User Data',
              description:
                'Indicates the AI model has been given customer data in order to improve its results.',
              value: 'No',
            },
          ],
        },
        {
          blockTitle: 'Second block',
          segmentData: [
            {
              segmentTitle: 'Very useful info',
              description: 'this info is super important',
              value: '1==1',
              valueDescription: "don't tell anyone",
            },
          ],
        },
      ],
    },
    dataPermissionLevels: [
      {
        name: 'Level 1',
        title: 'Descriptive Analytics and Research',
        description:
          'We leverage anonymized aggregate data for detailed analytics to inform model development and product improvements. No AI models are used at this level.',
        highlighted: true,
        level: 'level_1',
      },
      {
        name: 'Level 2',
        title: 'AI-Powered Features Without Data Retention',
        description:
          'We utilize off-the-shelf AI models and customer data as input to provide AI-powered features. No data is used for training this model.',
        level: 'level_2',
      },
    ],
    AiInformation: {
      featureName: 'Discussions Translation',
      permissionLevelText: 'Permission Level',
      permissionLevel: 'LEVEL 1',
      description:
        'We leverage anonymized aggregate data for detailed analytics to inform model development and product improvements. No AI models are used at this level.',
      permissionLevelsModalTriggerText: 'Permission Levels',
      modelNameText: 'Model Name',
      modelName: 'Haiku 3',
      nutritionFactsModalTriggerText: 'AI Nutrition Facts',
    },
  }

  it('renders without crashing', () => {
    render(<NutritionFacts {...defaultProps} />)
    expect(document.getElementById('nutrition_facts_trigger')).toBeInTheDocument()
  })

  it('renders correctly', () => {
    const {getByText} = render(<NutritionFacts {...defaultProps} />)
    const trigger = document.getElementById('nutrition_facts_trigger') as HTMLButtonElement
    fireEvent.click(trigger)
    expect(getByText(defaultProps.name)).toBeInTheDocument()
    expect(getByText(defaultProps.AiInformation.permissionLevel)).toBeInTheDocument()
    expect(getByText(defaultProps.AiInformation.modelName)).toBeInTheDocument()
  })

  it('renders permission level correctly', () => {
    const {getByText} = render(<NutritionFacts {...defaultProps} />)
    const trigger = document.getElementById('nutrition_facts_trigger') as HTMLButtonElement
    fireEvent.click(trigger)
    fireEvent.click(getByText(/AI Nutrition Facts/i))
    expect(getByText(defaultProps.nutritionFacts.data[0].blockTitle)).toBeInTheDocument()
    expect(
      getByText(defaultProps.nutritionFacts.data[0].segmentData[0].segmentTitle),
    ).toBeInTheDocument()
  })

  it('renders ai nutrition fact correctly', () => {
    const {getByText} = render(<NutritionFacts {...defaultProps} />)
    const trigger = document.getElementById('nutrition_facts_trigger') as HTMLButtonElement
    fireEvent.click(trigger)
    fireEvent.click(getByText(/AI Nutrition Facts/i))
    expect(getByText(defaultProps.nutritionFacts.data[0].blockTitle)).toBeInTheDocument()
    expect(
      getByText(defaultProps.nutritionFacts.data[0].segmentData[0].segmentTitle),
    ).toBeInTheDocument()
    expect(
      getByText(defaultProps.nutritionFacts.data[0].segmentData[1].segmentTitle),
    ).toBeInTheDocument()
    expect(getByText(defaultProps.nutritionFacts.data[0].segmentData[1].value)).toBeInTheDocument()
  })

  it('renders permission level modal correctly', () => {
    const {getByText} = render(<NutritionFacts {...defaultProps} />)
    const trigger = document.getElementById('nutrition_facts_trigger') as HTMLButtonElement
    fireEvent.click(trigger)
    fireEvent.click(getByText(/Permission Levels/i))
    expect(getByText(defaultProps.dataPermissionLevels[0].title)).toBeInTheDocument()
  })
})
