import React from 'react'
import ReactDOM from 'react-dom'
import MasqueradeModal from 'jsx/masquerade/MasqueradeModal'

ReactDOM.render((
  <MasqueradeModal user={ENV.masquerade_modal_data.user} />
), document.getElementById('masquerade_modal'))
