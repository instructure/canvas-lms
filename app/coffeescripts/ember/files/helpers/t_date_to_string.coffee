define ['ember', 'jquery', 'jquery.instructure_date_and_time'], (Ember, $) ->

  # SUPER LAME ALERT!!!
  # we do this same thing in 'compiled/ember/quizzes/helpers/t_date_to_string'
  # and 'compiled/handlebars_helpers' all in subtly different ways.
  # let's just use one!
  Ember.Handlebars.helper 'friendlyDatetime', (datetime, {hash: {pubdate}}) ->
    return '' unless datetime
    new Ember.Handlebars.SafeString """
      <time
        title='#{$.datetimeString(datetime)}'
        datetime='#{datetime.toISOString()}'
        #{if pubdate then 'pubdate' else ''}
      >
        #{$.friendlyDatetime(datetime)}
      </time>
    """