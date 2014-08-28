# From: http://deftcode.com/code/flickr_upload/multipartpost.rb
## Helper class to prepare an HTTP POST request with a file upload
## Mostly taken from
#http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/113774
### WAS:
## Anything that's broken and wrong probably the fault of Bill Stilwell
##(bill@marginalia.org)
### NOW:
## Everything wrong is due to keith@oreilly.com

require "canvas_slug"
require "mime/types"
require "net/http"
require "cgi"
require "base64"

module Multipart
  require "multipart/file_param"
  require "multipart/param"
  require "multipart/post"
end
