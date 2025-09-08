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

import {render} from '@testing-library/react'
import CanvasAiInformation from '../AiInformation'
import userEvent from '@testing-library/user-event'

const props = {
  featureName: 'Test Feature',
  modelName: 'Test Model',
  isTrainedWithUserData: false,
  dataRetention: 'No data retention',
  dataLogging: 'No data logging',
  dataSharedWithModel: 'No data shared with model',
  regionsSupported: 'US',
  isPIIExposed: false,
  isFeatureBehindSetting: true,
  isHumanInTheLoop: false,
  expectedRisks: 'No risks',
  intendedOutcomes: 'Assist users with completing tasks',
  permissionsLevel: 2,
  triggerButton: <button>Open AI Info</button>,
}

describe('CanvasAiInformation', () => {
  it('renders with popover correctly', async () => {
    const user = userEvent.setup()
    const {getByText} = render(<CanvasAiInformation {...props} />)
    const openButton = getByText('Open AI Info')
    await user.click(openButton)

    expect(getByText('Test Feature')).toBeInTheDocument()
    expect(getByText(props.modelName)).toBeInTheDocument()
    // determined by permissionsLevel prop
    expect(getByText('LEVEL 2')).toBeInTheDocument()
    expect(getByText(/We utilize off-the-shelf AI models/)).toBeInTheDocument()
  })

  it('renders permission levels correctly', async () => {
    const user = userEvent.setup()
    const {getByText} = render(<CanvasAiInformation {...props} />)
    const openButton = getByText('Open AI Info')
    await user.click(openButton)

    // open permissions modal
    const permissionLevelsLink = getByText('Permission Levels')
    await user.click(permissionLevelsLink)
    // if a permission is highlighted, "Current Feature:" text renders above a permission level
    expect(getByText('Current Feature:')).toBeInTheDocument()
  })

  it('renders nutrition facts correctly', async () => {
    const user = userEvent.setup()
    const {getByText} = render(<CanvasAiInformation {...props} />)
    const openButton = getByText('Open AI Info')
    await user.click(openButton)

    // open nutrition facts modal
    const nutritionFactsLink = getByText('AI Nutrition Facts')
    await user.click(nutritionFactsLink)
    expect(getByText(props.dataRetention)).toBeInTheDocument()
    expect(getByText(props.dataLogging)).toBeInTheDocument()
    expect(getByText(props.dataSharedWithModel)).toBeInTheDocument()
    expect(getByText(props.regionsSupported)).toBeInTheDocument()
    expect(getByText(props.expectedRisks)).toBeInTheDocument()
    expect(getByText(props.intendedOutcomes)).toBeInTheDocument()
  })
})
