
module.exports = function(input){
  this.cacheable();
  var newInput = input;

  // Make I18n available on the window so that libraries
  // that expect to find it there don't die
  var i18nRegexp = /["']vendor\/i18n['"]/;
  newInput = newInput.replace(i18nRegexp, function(match){
    return match.replace("vendor", "expose?I18n!exports?I18n!vendor");
  });

  // shim tinymce through our webpack-specific helper that takes
  // the special globally exposed things and munge them together
  // with the core tinymce exported object (public/javascripts/shims/tinymce.js)
  var tinyMceRegexp = /['"]bower\/tinymce\/tinymce["']/;
  newInput = newInput.replace(tinyMceRegexp, "'shims/tinymce'");

  var emberRegex = /['"]ember["']/;
  newInput = newInput.replace(emberRegex, "'shims/ember'");
  return newInput;
}
