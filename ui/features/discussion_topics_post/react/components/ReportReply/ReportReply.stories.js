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
import {ReportReply} from './ReportReply'

export default {
  title: 'Examples/Discussion Posts/Components/ReportReply',
  component: ReportReply,
  argTypes: {},
}

const Template = args => {
  return <ReportReply {...args} />
}

export const Default = Template.bind({})
Default.args = {
  onCloseReportModal: () => {},
  onSubmit: () => {},
  showReportModal: true,
}

export const Loading = Template.bind({})
Loading.args = {
  onCloseReportModal: () => {},
  onSubmit: () => {},
  showReportModal: true,
  isLoading: true,
}
