# @return {Boolean}
#   Whether the browser has a usable localStorage.
define [], ->
  return false if !window.hasOwnProperty('localStorage') # < IE8

  tmpKey = '__cnvs_test__'
  tmpValue = null

  try
    localStorage.setItem(tmpKey, 'yes')
    tmpValue = localStorage.getItem(tmpKey)
    localStorage.removeItem(tmpKey)
  catch e
    tmpValue = null

  tmpValue == 'yes'