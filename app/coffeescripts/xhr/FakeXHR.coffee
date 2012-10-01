# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'jquery'
], ($) ->

  # Used to make a fake XHR request, useful if there are errors on an
  # asynchronous request generated using the iframe trick.
  #
  # We don't actually care about some of this stuff, but we stub out all XHR so
  # that things that try to use it don't blow up.
  class FakeXHR
    constructor: ->
      @readyState      = 0
      @timeout         = 0
      @withCredentials = false

    ##
    # we assume all responses are json
    setResponse: (body) ->
      @readyState = 4
      @responseText = body

      try
        @response = $.parseJSON(body)
      catch e
        @status       = 500
        @statusText   = "500 Internal Server Error"
        return

      if @response.errors
        @status = 400
        @statusText = "400 Bad Request"
      else
        @status = 200
        @statusText = "200 OK"
      @responseType = "json"

    abort: ->
    getAllResponseHeaders: -> if @responseText then "" else null
    getResponseHeader: ->
    open: ->
    overrideMimeType: ->
    send: ->
    setRequestHeader: ->
      