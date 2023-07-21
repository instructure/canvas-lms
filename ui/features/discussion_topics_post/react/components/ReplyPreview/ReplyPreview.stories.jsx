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
import {ReplyPreview} from './ReplyPreview'

export default {
  title: 'Examples/Discussion Posts/Components/ReplyPreview',
  component: ReplyPreview,
  argTypes: {},
}

const Template = args => <ReplyPreview {...args} />

export const Default = Template.bind({})
Default.args = {
  createdAt: '2021-08-10T12:10:38-06:00',
  previewMessage:
    'Differences of habit and language are nothing at all if our aims are identical and our hearts are open.',
  author: {
    shortName: 'Albus Dumbledore',
  },
  editor: {
    shortName: 'Harry Potter',
  },
  deleted: false,
}
