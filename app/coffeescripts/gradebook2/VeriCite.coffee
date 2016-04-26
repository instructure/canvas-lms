define [
  'i18n!vericite'
  'underscore'
], (I18n, {max, invert}) ->

  VeriCite =
    extractDataVeriCite: (submission) ->
      return unless submission?.vericite_data
      data = items: []
  
      if submission.attachments and submission.submission_type is 'online_upload'
        for attachment in submission.attachments
          attachment = attachment.attachment ? attachment
          if vericite = submission.vericite_data?['attachment_' + attachment.id]
            data.items.push vericite
      else if submission.submission_type is "online_text_entry"
        if vericite = submission.vericite_data?['submission_' + submission.id]
          data.items.push vericite
  
      return unless data.items.length

      stateList = ['no', 'none', 'acceptable', 'warning', 'problem', 'failure']
      stateMap = invert(stateList)
      states = (parseInt(stateMap[item.state or 'no']) for item in data.items)
      data.state = stateList[max(states)]
      data

    extractDataForVeriCite: (submission, key, urlPrefix) ->
      data = submission.vericite_data
      return {} unless data and data[key] and data[key].similarity_score?
      data = data[key]
      data.state = "#{data.state || 'no'}_score"
      data.score = "#{data.similarity_score}%"
      data.reportUrl = "#{urlPrefix}/assignments/#{submission.assignment_id}/submissions/#{submission.user_id}/vericite/#{key}"
      data.tooltip = I18n.t('tooltip.score', 'VeriCite Similarity Score - See detailed report')
      data
