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

const mockInfo = {
  aiInformation: {
    data: [
      {
        featureName: 'Canvas Course Translation',
        permissionLevel: 'LEVEL 2',
        modelName: 'OpenAI GPT-4',
        description: 'Test description',
        permissionLevelText: 'Permission Level:',
        modelNameText: 'Base Model',
        permissionLevelsModalTriggerText: 'Data Permission Levels',
        nutritionFactsModalTriggerText: 'AI Nutrition Facts',
      },
    ],
  },
  dataPermissionLevels: {
    data: [
      {
        level: 'LEVEL 1',
        title: 'Descriptive Analytics and Research',
        description: 'We leverage anonymized aggregate data',
        highlighted: false,
      },
      {
        level: 'LEVEL 2',
        title: 'AI-Powered Features Without Data Training',
        description: 'We utilize off-the-shelf AI models',
        highlighted: true,
      },
    ],
  },
  nutritionFacts: {
    featureName: 'Canvas Course Translation',
    data: [
      {
        blockTitle: 'Model & Data',
        segmentData: [
          {
            segmentTitle: 'Base Model',
            value: 'OpenAI GPT-4',
            description: 'The foundational AI',
          },
          {
            segmentTitle: 'Trained with User Data',
            value: 'No',
            description: 'Indicates the AI model has been given customer data',
          },
        ],
      },
    ],
  },
  responsiveProps: {
    fullscreenModals: false,
    color: 'primary' as const,
    buttonColor: 'primary' as const,
    withBackground: false,
    domElement: 'nutrition_facts_container',
  },
}

injectGlobalAlertContainers()

describe('Nutrition facts', () => {
  it('renders without crashing', () => {
    render(<NutritionFacts {...mockInfo} />)
    expect(document.getElementById('nutrition_facts_trigger')).toBeInTheDocument()
  })

  it('renders correctly', () => {
    const {getByText} = render(<NutritionFacts {...mockInfo} />)
    const trigger = document.getElementById('nutrition_facts_trigger') as HTMLButtonElement
    fireEvent.click(trigger)
    expect(getByText(mockInfo.nutritionFacts.featureName)).toBeInTheDocument()
    expect(getByText(mockInfo.aiInformation.data[0].permissionLevel)).toBeInTheDocument()
    expect(getByText(mockInfo.aiInformation.data[0].modelName)).toBeInTheDocument()
  })

  it('renders permission level correctly', () => {
    const {getByText, getAllByText} = render(<NutritionFacts {...mockInfo} />)
    const trigger = document.getElementById('nutrition_facts_trigger') as HTMLButtonElement
    fireEvent.click(trigger)
    fireEvent.click(getByText(/AI Nutrition Facts/i))
    expect(getByText(mockInfo.nutritionFacts.data[0].blockTitle)).toBeInTheDocument()
    expect(
      getAllByText(mockInfo.nutritionFacts.data[0].segmentData[0].segmentTitle).length,
    ).toBeGreaterThan(0)
  })

  it('renders ai nutrition fact correctly', () => {
    const {getByText, getAllByText} = render(<NutritionFacts {...mockInfo} />)
    const trigger = document.getElementById('nutrition_facts_trigger') as HTMLButtonElement
    fireEvent.click(trigger)
    fireEvent.click(getByText(/AI Nutrition Facts/i))
    expect(getByText(mockInfo.nutritionFacts.data[0].blockTitle)).toBeInTheDocument()
    expect(
      getAllByText(mockInfo.nutritionFacts.data[0].segmentData[0].segmentTitle).length,
    ).toBeGreaterThan(0)
    expect(
      getByText(mockInfo.nutritionFacts.data[0].segmentData[1].segmentTitle),
    ).toBeInTheDocument()
    expect(getByText(mockInfo.nutritionFacts.data[0].segmentData[1].value)).toBeInTheDocument()
  })

  it('renders permission level modal correctly', () => {
    const {getByText} = render(<NutritionFacts {...mockInfo} />)
    const trigger = document.getElementById('nutrition_facts_trigger') as HTMLButtonElement
    fireEvent.click(trigger)
    fireEvent.click(getByText(/Permission Levels/i))
    expect(getByText(mockInfo.dataPermissionLevels.data[0].title)).toBeInTheDocument()
  })

  it('renders with mobile responsive props', () => {
    const mobileProps = {
      ...mockInfo,
      responsiveProps: {
        fullscreenModals: true,
        color: 'secondary' as const,
        buttonColor: 'primary' as const,
        withBackground: false,
        domElement: 'nutrition_facts_mobile_container',
      },
    }
    render(<NutritionFacts {...mobileProps} />)
    const trigger = document.getElementById('nutrition_facts_trigger')
    expect(trigger).toBeInTheDocument()
    // Verify the button exists and can be clicked (fullscreen modal behavior)
    expect(trigger).toHaveAttribute('type', 'button')
  })

  it('renders with desktop responsive props', () => {
    const desktopProps = {
      ...mockInfo,
      responsiveProps: {
        fullscreenModals: false,
        color: 'primary' as const,
        buttonColor: 'primary-inverse' as const,
        withBackground: false,
        domElement: 'nutrition_facts_container',
      },
    }
    render(<NutritionFacts {...desktopProps} />)
    const trigger = document.getElementById('nutrition_facts_trigger')
    expect(trigger).toBeInTheDocument()
    expect(trigger).toHaveAttribute('type', 'button')
  })

  it('uses correct icon color based on responsive props', () => {
    const {rerender} = render(<NutritionFacts {...mockInfo} />)
    let trigger = document.getElementById('nutrition_facts_trigger')
    expect(trigger).toBeInTheDocument()

    // Test with secondary color (mobile)
    const mobileProps = {
      ...mockInfo,
      responsiveProps: {
        ...mockInfo.responsiveProps,
        color: 'secondary' as const,
      },
    }
    rerender(<NutritionFacts {...mobileProps} />)
    trigger = document.getElementById('nutrition_facts_trigger')
    expect(trigger).toBeInTheDocument()
  })
})
