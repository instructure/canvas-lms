define ->

  doc = window.document
  templatesWithStyles = {}

  registerTemplateCss = (templateId, css) ->
    templatesWithStyles[templateId] = css
    render()

  registerTemplateCss.clear = ->
    templatesWithStyles = {}
    render()

  render = ->
    strings = []
    for templateId, css of templatesWithStyles
      strings.push "/* From: #{templateId} */"
      strings.push css
    combined = strings.join '\n'
    styleNode = cleanStyleNode()
    if 'cssText' of styleNode
      styleNode.cssText = combined
    else
      styleNode.appendChild doc.createTextNode(combined)

  _styleNode = null
  cleanStyleNode = ->
    if _styleNode
      _styleNode.removeChild child while child = _styleNode.firstChild
      return _styleNode

    if doc.createStyleSheet
      _styleNode = doc.createStyleSheet()
    else
      head = doc.head || doc.getElementsByTagName('head')[0]
      _styleNode = doc.createElement('style')
      head.appendChild(_styleNode)

  return registerTemplateCss
