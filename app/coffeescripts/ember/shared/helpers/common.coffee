# This file gets included in all ember templates, ever, therefore:
#   - Only require helpers that are necessary for all ember apps.
#   - Be strict about what you include or allow to be included here.
#   - Don't write code here, include helpers from their own files

define [
  './t'
  './format-date'
  './n'
], ->
