#
# Copyright (C) 2013 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppCenterController do
  describe "#generate_app_api_collection" do
    let(:controller) do
      controller = AppCenterController.new
      controller.params = {}
      controller
    end

    it "generates a valid paginated collection" do
      objects = ['object1', 'object2']
      next_page = 10
      will_paginate = controller.generate_app_api_collection('www.example.com/endpoint') do |app_api, page|
        app_api.should be_a AppCenter::AppApi
        page.should == 1
        {
            'objects' => ['object1', 'object2'],
            'meta' => {"next_page" => next_page}
        }
      end
      will_paginate.should be_a PaginatedCollection::Proxy
      collection = will_paginate.paginate(:per_page => 72)
      collection.should == objects
      collection.next_page.should == next_page
    end

    it "handles an empty response" do
      will_paginate = controller.generate_app_api_collection('') {}
      will_paginate.paginate(:per_page => 50).should == []
    end

    it "passes the page param as the offset" do
      controller.params['page'] = 32
      controller.params['per_page'] = 12
      will_paginate = controller.generate_app_api_collection('') do |app_api, page, per_page|
        page.should == controller.params['page']
        per_page.should == controller.params['per_pages']
      end
    end
  end
end
