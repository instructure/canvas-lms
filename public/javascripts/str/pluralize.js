define(['jquery'], function($) {
    // ported pluralizations from active_support/inflections.rb
  // (except for cow -> kine, because nobody does that) 
  var skip = ['equipment', 'information', 'rice', 'money', 'species', 'series', 'fish', 'sheep', 'jeans'];
  var patterns = [
    [/person$/i, 'people'],
    [/man$/i, 'men'],
    [/child$/i, 'children'],
    [/sex$/i, 'sexes'],
    [/move$/i, 'moves'],
    [/(quiz)$/i, '$1zes'],
    [/^(ox)$/i, '$1en'],
    [/([m|l])ouse$/i, '$1ice'],
    [/(matr|vert|ind)(?:ix|ex)$/i, '$1ices'],
    [/(x|ch|ss|sh)$/i, '$1es'],
    [/([^aeiouy]|qu)y$/i, '$1ies'],
    [/(hive)$/i, '$1s'],
    [/(?:([^f])fe|([lr])f)$/i, '$1$2ves'],
    [/sis$/i, 'ses'],
    [/([ti])um$/i, '$1a'],
    [/(buffal|tomat)o$/i, '$1oes'],
    [/(bu)s$/i, '$1ses'],
    [/(alias|status)$/i, '$1es'],
    [/(octop|vir)us$/i, '$1i'],
    [/(ax|test)is$/i, '$1es'],
    [/s$/i, 's']
  ];

  var pluralize = function(string) {
    string = string || '';
    if ($.inArray(string, skip) > 0) {
      return string;
    }
    for (var i = 0; i < patterns.length; i++) {
      var pair = patterns[i];
      if (string.match(pair[0])) {
        return string.replace(pair[0], pair[1])
      }
    }
    return string + "s";
  };

  pluralize.withCount = function(count, string) {
    return "" + count + " " + (count == 1 ? string : pluralize(string));
  };

  return pluralize;
});
