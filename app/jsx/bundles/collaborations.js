import $ from 'jquery'
import CollaborationsPage from 'compiled/views/collaborations/CollaborationsPage'
import 'collaborations'
import 'compiled/behaviors/activate'

const page = new CollaborationsPage({el: $('body')})
page.initPageState()
