/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
  title: 'Examples/Canvas Inbox/AttachmentDisplay',
  component: AttachmentDisplay,
  argTypes: {
    onReplaceItem: {action: 'Replace'},
    onDeleteItem: {action: 'Delete'},
  },
}

const Template = args => <AttachmentDisplay {...args} />

export const Default = Template.bind({})
Default.args = {
  attachments: [
    {id: '1', displayName: 'Foo Bar'},
    {id: '2', displayName: 'Bar Foo'},
  ],
}

export const LargeAttachmentCount = Template.bind({})
LargeAttachmentCount.args = {
  attachments: [...Array(30).keys()].map(i => {
    return {id: i.toString(), displayName: `Attachment ${i.toString()}`}
  }),
}

export const WithThumbnailPreview = Template.bind({})
WithThumbnailPreview.args = {
  attachments: [
    {id: '1', displayName: 'Small Thumbnail', thumbnailUrl: 'https://placehold.it/48x48'},
    {id: '2', displayName: 'Large Thumbnail', thumbnailUrl: 'https://placehold.it/480x480'},
    {id: '3', displayName: 'Oblong Thumbnail', thumbnailUrl: 'https://placehold.it/480x48'},
  ],
}

export const WithLongDisplayName = Template.bind({})
WithLongDisplayName.args = {
  attachments: [{id: '1', displayName: 'longer and '.repeat(10).concat('longer')}],
}
