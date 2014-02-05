require [
  'jquery'
  'compiled/views/collaborations/CollaborationsPage'
  'collaborations'
], ($, CollaborationsPage) ->
  page = new CollaborationsPage(el: $('body'))
  page.initPageState() 
