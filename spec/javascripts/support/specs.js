require([
  'vendor/jquery-1.6.4', // get rid of this (and make the specs and/or the modules they are testing require jquery) when jquery is a module
  'specs/TemplateSpec',
  'specs/CustomListSpec',
  'specs/invokerSpec',
  'specs/jQuery.instructureMiscPluginsSpec',
  'specs/userNamePartsSpec',
  'specs/objectCollectionSpec',
  'specs/util/BackoffPollerSpec',
  'specs/jQuery.instructureJqueryPatches'
]);

