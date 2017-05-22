#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

Feature.register('submissions_folder' => {
  display_name: -> { I18n.t('Submissions Folder') },
  description: -> { I18n.t('Upload files submitted with assignments to a special read-only Submissions folder') },
  applies_to: 'RootAccount',
  state: 'hidden',
  custom_transition_proc: ->(user, context, from_state, transitions) {
    if from_state == 'on'
      transitions['off'] = { 'locked' => true, 'message' => I18n.t('This feature cannot be disabled once it has been turned on.') }
    else
      transitions['on'] = { 'locked' => false, 'message' => I18n.t('Once this feature is enabled, you will not be able to turn it off again.  Ensure you are ready to enable the Submissions Folder before proceeding.') }
    end
  }
})
