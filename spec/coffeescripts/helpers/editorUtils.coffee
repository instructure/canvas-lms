define ['jsx/shared/rce/serviceRCELoader'], (RCELoader) ->
  return {
    resetRCE: ()=>
      window.tinyrce = null
      window.RceModule = null
      RCELoader.cachedModule = null
      RCELoader.loadingFlag = false
      RCELoader.loadingCallbacks = []
  }
