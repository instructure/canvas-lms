define [], ->
  forceScreenreaderToReparse = (node) ->
    node.style.display = 'none'
    node.offsetHeight
    node.style.display = ''