define([
   'jquery'
], ($) => {
   const makeAPICall = (ruleUrl, jwt) => {
      return $.ajax({
          dataType: 'json',
          url: ruleUrl,
          headers: {
            Authorization: 'Bearer ' + jwt
          }
         });
   }

  const cyoeClient = {
    getStats: (ruleId, jwt, url) => {
      const _ruleUrl = url + '?trigger_assignment=' + ruleId;

      return makeAPICall(_ruleUrl, jwt)
    }
  }

  return cyoeClient;
});