/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import Carousel from './Carousel'

export default {
  title: 'Examples/Evaluate/Gradebook/Carousel',
  component: Carousel,
  args: {
    children: 'Book Report',
    disabled: false,
    displayLeftArrow: true,
    displayRightArrow: true,
    leftArrowDescription: 'Previous',
    onLeftArrowClick() {},
    onRightArrowClick() {},
    rightArrowDescription: 'Next',
  },
}

const Template = args => <Carousel {...args} />
export const Default = Template.bind({})
