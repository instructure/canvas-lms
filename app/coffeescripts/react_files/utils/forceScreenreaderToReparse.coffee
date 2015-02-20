define [], ()->
  ##
  # Preface: This is a horrible terrible function and should only be used
  #          in the most dire circumstances.  In fact, it probably shouldn't
  #          exist at all.
  #
  # This function will cause a given DOM node to be completely thrown away and
  # re-rendered.  This is helpful to screenreaders because JavaScripty stuff
  # doesn't work so well.  They generally read the page once and call it good.
  #
  # The biggest instance of this problem is on the ShowFolder area.  The version
  # of react-router in use has a prop called "addHandlerKey" which is used by
  # New Files extensively.  What this property causes react-router to do is add
  # in keys to the thing it renders which prevents the DOM from being thrown
  # when an update happens.  Removing this prop causes New Files to break at the
  # moment.  However, this prop doesn't exist in the latest version of
  # react-router so it should be removed during the upgrade.
  #
  # Ideally the problem that this function solves will not exist after that
  # upgrade happens.
  #
  # *******PLEASE REMOVE THIS FUNCTION WHENEVER IT CAN BE DONE*******
  ##
  forceScreenreaderToReparse = (node) ->

    # Save the scroll position since the thrash will cause the browser to scroll
    # to the top.
    YscrollPosition = window.scrollY
    XscrollPosition = window.scrollX

    # Thrash the DOM for the node we've been given.
    node.style.display = 'none'
    node.offsetHeight
    node.style.display = ''

    # Force the browser to scroll back to the original position.
    window.scroll(XscrollPosition, YscrollPosition)