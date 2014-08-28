define(function() {
  /**
   */
  return function fromJSONAPI(payload, collKey, wantsObject) {
    var data = {};

    if (payload) {
      if (payload[collKey]) {
        data = payload[collKey];
      }
      else {
        data = payload;
      }
    }

    if (wantsObject && Array.isArray(data)) {
      return data[0];
    }
    else {
      return data;
    }
  };
});