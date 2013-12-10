var parent = require('loom/lib/generic_generator');
var msg = require('loom/lib/message');

exports.before = function(env) {
  if (!env.args[0]) {
    msg.error("You must specify an app name, ie 'generate app inbox'");
  }
  env.appName = env.args[0];
};

exports.present = function(appName) {
  return {
    appName: appName
  }
};

exports.templates = [
  'new_app/config/app.coffee.hbs',
  'new_app/config/routes.coffee.hbs',
  'new_app/templates/application.hbs.hbs',
  'new_app/tests/app.coffee.hbs',
  'new_app/tests/app.spec.coffee.hbs'
];

exports.savePath = function(template, env) {
  // lol
  return {
    'new_app/config/app.coffee.hbs': 'app/coffeescripts/ember/'+env.appName+'/config/app.coffee',
    'new_app/config/routes.coffee.hbs': 'app/coffeescripts/ember/'+env.appName+'/config/routes.coffee',
    'new_app/templates/application.hbs.hbs': 'app/coffeescripts/ember/'+env.appName+'/templates/'+env.appName+'.hbs',
    'new_app/tests/app.coffee.hbs': 'app/coffeescripts/ember/'+env.appName+'/tests/app.coffee',
    'new_app/tests/app.spec.coffee.hbs': 'app/coffeescripts/ember/'+env.appName+'/tests/app.spec.coffee'
  }[template];
};


