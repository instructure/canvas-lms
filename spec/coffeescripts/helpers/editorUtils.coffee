define [
  'jsx/shared/rce/serviceRCELoader'
  'jsx/shared/rce/Sidebar'
], (RCELoader, Sidebar) ->
  return {
    resetRCE: ()=>
      window.tinyrce = null
      window.RceModule = null
      RCELoader.cachedModule = null
      RCELoader.loadingFlag = false
      RCELoader.loadingCallbacks = []
      Sidebar.reset()
  }
