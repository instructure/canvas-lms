require [
  'react',
  'jsx/navigation_header/Navigation',
], (React, Navigation) ->

  React.render(Navigation(), document.getElementById('global_nav_tray_container'))

