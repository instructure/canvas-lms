#
# Copyright (C) 2012 - present Instructure, Inc.
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

define [
  'i18n!turnitin'
  'underscore'
], (I18n, {max, invert}) ->

  Turnitin =
    extractDataTurnitin: (submission) ->
      plagData = submission?.turnitin_data
      if !plagData?
        plagData = submission?.vericite_data
      return unless plagData?
      data = items: []

      if submission.attachments and submission.submission_type is 'online_upload'
        for attachment in submission.attachments
          attachment = attachment.attachment ? attachment
          if turnitin = plagData?['attachment_' + attachment.id]
            data.items.push turnitin
      else if submission.submission_type is "online_text_entry"
        if turnitin = plagData?['submission_' + submission.id]
          data.items.push turnitin

      return unless data.items.length

      stateList = ['no', 'none', 'acceptable', 'warning', 'problem', 'failure', 'pending', 'error']
      stateMap = invert(stateList)
      states = (parseInt(stateMap[item.state or 'no']) for item in data.items)
      data.state = stateList[max(states)]
      data

    extractDataForTurnitin: (submission, key, urlPrefix) ->
      data = submission?.turnitin_data
      type = "turnitin"
      if !data? || (submission?.vericite_data && submission?.vericite_data.provider == 'vericite')
        data = submission?.vericite_data
        type = "vericite"
      if submission?.has_originality_report
        type = "originality_report"
      return {} unless data and data[key] and (data[key].similarity_score? or data[key].status == 'pending')
      data = data[key]
      data.state = "#{data.state || 'no'}_score"
      data.score = if data.similarity_score then "#{data.similarity_score}%" else ""
      data.reportUrl = "#{urlPrefix}/assignments/#{submission.assignment_id}/submissions/#{submission.user_id}/#{type}/#{key}"
      data.tooltip = I18n.t('tooltip.score', 'Similarity Score - See detailed report')
      data
