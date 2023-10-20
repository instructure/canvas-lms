# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
#
# This file is part of Canvas.
#
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

# From: http://deftcode.com/code/flickr_upload/multipartpost.rb
## Helper class to prepare an HTTP POST request with a file upload
## Mostly taken from
# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/113774
### WAS:
## Anything that's broken and wrong probably the fault of Bill Stilwell
# #(bill@marginalia.org)
### NOW:
## Everything wrong is due to keith@oreilly.com

require "mime/types"
require "net/http"
require "cgi"
require "base64"

require_relative "legacy_multipart/file_param"
require_relative "legacy_multipart/param"
require_relative "legacy_multipart/terminator"
require_relative "legacy_multipart/sequenced_stream"
require_relative "legacy_multipart/post"
