define([
  'jquery',
], ($) => {
  const CyoeClient = {
    call ({ apiUrl, jwt }, path) {
      return $.ajax({
        dataType: 'json',
        url: apiUrl + path,
        headers: {
          Authorization: 'Bearer ' + jwt,
        },
      })
    },

    loadInitialData (state) {
      const path = '?trigger_assignment=' + state.assignment.id
      return CyoeClient.call(state, path)
    },
  }

  return CyoeClient
})
