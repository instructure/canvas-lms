/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {AttachmentDisplay} from './AttachmentDisplay'

export default {
  title: 'Examples/Discussion Posts/Components/AttachmentDisplay',
  component: AttachmentDisplay,
  argTypes: {},
}

const Template = args => <AttachmentDisplay {...args} />

export const AttachmentPresent = Template.bind({})
AttachmentPresent.args = {
  attachments: [
    {
      id: 1,
      display_name: 'file_name.file',
      url: 'file_download_example.com',
    },
  ],
  setAttachments: () => {},
  setAttachmentsToUpload: () => {},
}

export const NoAttachment = Template.bind({})
NoAttachment.args = {
  attachments: [],
  setAttachments: () => {},
  setAttachmentsToUpload: () => {},
}
