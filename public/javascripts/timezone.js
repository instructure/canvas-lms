// the file needs to be a plugin to load ENV.TIMEZONE and ENV.LOCALE into the
// tz object, but we don't want to have to call it as a plugin everywhere,
// hence this wrapper
define(['timezone_plugin!'], function(tz) { return tz; });
