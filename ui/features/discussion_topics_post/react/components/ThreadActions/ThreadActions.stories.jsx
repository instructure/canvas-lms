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

import {ThreadActions} from './ThreadActions'

export default {
  title: 'Examples/Discussion Posts/Components/ThreadActions',
  component: ThreadActions,
  argTypes: {
    goToTopic: {action: 'goToTopic'},
    goToParent: {action: 'goToParent'},
    goToQuotedReply: {action: 'goToQuotedReply'},
    onEdit: {action: 'onEdit'},
    onDelete: {action: 'onDelete'},
    onMarkAllAsUnread: {action: 'onMarkAsUnread'},
    onToggleUnread: {action: 'onToggleUnread'},
    openInSpeedGrader: {action: 'openInSpeedGrader'},
    onReport: {action: 'onReport'},
  },
}

const Template = args => <ThreadActions {...args} />

export const Default = Template.bind({})
Default.args = {}

export const TeacherView = Template.bind({})
TeacherView.args = {}

export const OwnerView = Template.bind({})
OwnerView.args = {
  openInSpeedGrader: null,
}

export const OtherStudentView = Template.bind({})
OtherStudentView.args = {
  onDelete: null,
  onEdit: null,
  openInSpeedGrader: null,
}

export const UnreadThread = Template.bind({})
UnreadThread.args = {
  isUnread: true,
}

export const ReadThread = Template.bind({})
ReadThread.args = {
  isUnread: false,
}

export const Reported = Template.bind({})
Reported.args = {
  isReported: true,
}
