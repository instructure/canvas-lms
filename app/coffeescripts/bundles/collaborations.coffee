require [
  'jquery'
  'compiled/views/collaborations/CollaborationsPage'
  'collaborations'
  'compiled/behaviors/activate'
], ($, CollaborationsPage) ->
  page = new CollaborationsPage(el: $('body'))
  page.initPageState() 
