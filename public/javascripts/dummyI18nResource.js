// Webpack wants to be able to resolve every module before
// building.  Because we use a pitching loader for i18n tags,
// we never make it to the resource itself (or shouldn't). However,
// We need to give webpack a resource that exists on the Filesystem
// before the pitching i18n loader catches it, so we replace
// i18n!some-scope requires with i18n?some-scope!dummyI18nResource
define([],function(){
  throw "Should never actually call this module";
});
