#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative '../spec_helper'

# A MockStaticSite blocks any requests to the specified host, and instead
# returns a corresponding file (using the path in the request) from the
# specified local directory.
#
# E.g., do MockStaticSite.new('fakesite.test', 'fake_site'). Then,
# a request to http://fakesite.test/avatars/1.jpg would receive
# the file that's at ./mock_static_sites/fake_site/avatars/1.jpg.
#
# The requested file is stored in-memory before getting returned, so this
# shouldn't be used for massive files. Plain text, Javascript files, and
# reasonably-sized images will be fine.

MOCK_SITES_DIRECTORY = 'mock_static_sites'.freeze

class NonexistentMockSiteError < StandardError
end

class MockStaticSite

  attr_accessor :mock_site, :index_file, :root_dir_path

  def initialize(url, mock_site)
    @url = url
    @mock_site = mock_site.to_s

    current_location = File.expand_path(File.dirname(__FILE__))
    @root_dir_path = "#{current_location}/#{MOCK_SITES_DIRECTORY}/#{mock_site}"
    begin
      root_dir = Dir.entries(root_dir_path)
    rescue Errno::ENOENT
      raise NonexistentMockSiteError,
            "There is no directory for #{mock_site}; create one at #{root_dir_path}"
    end
 
    index = root_dir.index { |file_name| file_name.start_with?('index.') }
    @index_file = index ? root_dir[index] : nil

    WebMock.enable!
    set_stub
  end
  
  private
  
  def set_stub
    WebMock.stub_request(:get, /#{Regexp.quote(@url)}/).to_return do |request|
      file_name = get_requested_file_name(request.uri.path)
      file_path = "#{root_dir_path}/#{file_name}"

      {
        body: File.read(file_path)
      }
    end
  end

  def get_requested_file_name(path)
    if ['', '/'].include?(path) && index_file
      index_file
    else
      path
    end
  end
end
