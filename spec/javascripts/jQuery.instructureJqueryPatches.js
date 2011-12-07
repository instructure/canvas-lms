(function() {
  define(['jquery.instructure_jquery_patches'], function(jQuery) {
    module('instructure jquery patches');
    return test('parseJSON', function() {
      deepEqual(jQuery.parseJSON('{ "var1": "1", "var2" : 2 }'), {
        "var1": "1",
        "var2": 2
      }, 'should still parse without the prefix');
      return deepEqual(jQuery.parseJSON('while(1);{ "var1": "1", "var2" : 2 }'), {
        "var1": "1",
        "var2": 2
      }, 'should parse with the prefix');
    });
  });
}).call(this);
