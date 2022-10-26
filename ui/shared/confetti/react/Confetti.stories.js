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

import React from 'react'
import {Button} from '@instructure/ui-buttons'

import Confetti from './Confetti'

export default {
  title: 'Examples/Shared/Confetti',
  component: Confetti,
}

const Template = args => {
  window.ENV = {
    confetti_branding_enabled: true,
    ...args,
  }
  const [count, updateCount] = React.useState(0)
  return (
    <>
      <Confetti {...args} triggerCount={count} />
      <Button onClick={() => updateCount(count + 1)}>Splash Confetti!</Button>
    </>
  )
}

export const DefaultColors = Template.bind({})

export const SingleCustomColor = Template.bind({})
SingleCustomColor.args = {
  active_brand_config: {
    variables: {
      'ic-brand-primary': '#0000ff',
    },
  },
}

export const MultipleCustomColors = Template.bind({})
MultipleCustomColors.args = {
  active_brand_config: {
    variables: {
      'ic-brand-primary': '#0000ff',
      'ic-brand-global-nav-bgd': '#ff00ff',
    },
  },
}

export const CustomLogo = Template.bind({})
CustomLogo.args = {
  active_brand_config: {
    variables: {
      'ic-brand-header-image': '/favicon.ico',
    },
  },
}

export const FullyBranded = Template.bind({})
FullyBranded.args = {
  active_brand_config: {
    variables: {
      'ic-brand-primary': '#000000',
      'ic-brand-global-nav-bgd': '#ff0000',
      'ic-brand-header-image': '/favicon.ico',
    },
  },
}

export const TallLogo = Template.bind({})
TallLogo.args = {
  active_brand_config: {
    variables: {
      'ic-brand-header-image': 'http://placekitten.com/200/300',
    },
  },
}

export const WideLogo = Template.bind({})
WideLogo.args = {
  active_brand_config: {
    variables: {
      'ic-brand-header-image': 'http://placekitten.com/300/200',
    },
  },
}
