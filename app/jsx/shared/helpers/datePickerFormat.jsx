// translate a strftime style format string (guaranteed to only use %d, %-d,
// %b, and %Y, though in dynamic order) into a datepicker style format string
define([], () => format => format.replace(/%Y/, 'yy').replace(/%b/, 'M').replace(/%-?d/, 'd').replace(/%a/, 'D'))
