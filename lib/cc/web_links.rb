#
# Copyright (C) 2011 Instructure, Inc.
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
module CC
  module WebLinks
    def add_web_links
      @manifest.weblinks.each do |tag|
        # the CC Web Link
        link_file_name = "#{tag[:migration_id]}.xml"
        link_path = File.join(@export_dir, link_file_name)
        link_file = File.new(link_path, 'w')
        link_doc = Builder::XmlMarkup.new(:target=>link_file, :indent=>2)
        link_doc.instruct!
  
        link_doc.webLink("xmlns" => "http://www.imsglobal.org/xsd/imsccv1p1/imswl_v1p1",
                        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                        "xsi:schemaLocation"=> "http://www.imsglobal.org/xsd/imsccv1p1/imswl_v1p1 http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imswl_v1p1.xsd"
        ) do |l|
          l.title tag[:title]
          l.url(:href => tag[:url])
        end
        link_file.close
        
        @resources.resource(
                :identifier => tag[:migration_id],
                "type" => CCHelper::WEB_LINK
        ) do |res|
          res.file(:href=>link_file_name)
        end
      end
    end
  end
end