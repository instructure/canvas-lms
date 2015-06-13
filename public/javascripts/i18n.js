// RequireJS I18n Plugin
//
// Used to require a specific I18n scope into your module
//
// ex.
//
//  define ['i18n!quizzes'], (I18n) ->
//    # I18n is automatically scoped to quizzes in here
//    I18n.t 'some_key', 'English translation'
//

define({
  load: function(name, req, load, config) {

    // don't translate if require.config({translate: false})
    if (!config.translate) {
      req(['i18nObj'], function(I18n) {
        load( I18n.scoped(name) );
      });
      return;
    }

    // also require the translations when config.translate is true. note
    // that build.js concats _core, but we still need to actually require it.
    req(['i18nObj', 'translations/' + name, 'translations/_core'], function(I18n) {
      load( config.isBuild ? null : I18n.scoped(name) );
    });
  }
});

