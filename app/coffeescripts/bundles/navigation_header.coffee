require [
  'react',
  'jsx/navigation_header/Navigation',
], (React, Navigation) ->

  Nav = React.createElement(Navigation);
  React.render(Nav, document.getElementById('global_nav_tray_container'))

