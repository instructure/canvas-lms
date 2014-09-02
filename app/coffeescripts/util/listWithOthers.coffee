define [
  'i18n!conversations'
  'jquery'
  'str/htmlEscape'
  'jquery.instructure_misc_helpers'
], (I18n, $, h) ->

  (strings, cutoff = 2) ->
    if strings.length > cutoff
      strings = strings[0...cutoff].concat([strings[cutoff...strings.length]])
    $.toSentence(for strOrArray in strings
      if typeof strOrArray is 'string' or strOrArray._icHTMLSafe
        "<span>#{h(strOrArray)}</span>"
      else
        """
        <span class='others'>
          #{h(I18n.t('other', 'other', count: strOrArray.length))}
          <span>
            <ul>
              #{(('<li>' + h(str) + '</li>') for str in strOrArray).join('')}
            </ul>
          </span>
        </span>
        """
    )
