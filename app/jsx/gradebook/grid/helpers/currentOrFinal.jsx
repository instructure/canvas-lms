define([], function() {
  var currentOrFinal = function(toolbarOptions) {
    if (toolbarOptions.treatUngradedAsZero) {
      return 'final';
    }

    return 'current';
  };

  return currentOrFinal;
})
