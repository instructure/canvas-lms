// THIS FILE IS ONLY FOR RequireJS. Not needed for Webpack
// the file needs to be a plugin to load ENV.TIMEZONE and ENV.BIGEASY_LOCALE into the
// tz object, but we don't want to have to call it as a plugin everywhere,
// hence this wrapper
define(['timezone_plugin!'], function(tz) { return tz; });
