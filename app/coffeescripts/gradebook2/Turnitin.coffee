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

      stateList = ['no', 'none', 'acceptable', 'warning', 'problem', 'failure']
      stateMap = invert(stateList)
      states = (parseInt(stateMap[item.state or 'no']) for item in data.items)
      data.state = stateList[max(states)]
      data

    extractDataForTurnitin: (submission, key, urlPrefix) ->
      data = submission?.turnitin_data
      type = "turnitin"
      if !data? || data.provider == 'vericite'
        data = submission?.vericite_data
        type = "vericite"
      return {} unless data and data[key] and data[key].similarity_score?
      data = data[key]
      data.state = "#{data.state || 'no'}_score"
      data.score = "#{data.similarity_score}%"
      data.reportUrl = "#{urlPrefix}/assignments/#{submission.assignment_id}/submissions/#{submission.user_id}/#{type}/#{key}"
      data.tooltip = I18n.t('tooltip.score', 'Similarity Score - See detailed report')
      data
