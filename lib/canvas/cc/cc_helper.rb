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
module Canvas::CC
module CCHelper
  IMS_DATE = "%Y-%m-%d"
  IMS_DATETIME = "%Y-%m-%dT%H:%M:%S"
  MANIFEST = 'imsmanifest.xml'
  LOR = "associatedcontent/imscc_xmlv1p0/learning-application-resource"
  WEBCONTENT = "webcontent"
  
  OBJECT_TOKEN = "$CANVAS_OBJECT_REFERENCE$"
  COURSE_TOKEN = "$CANVAS_COURSE_REFERENCE$"
  WIKI_TOKEN = "$WIKI_REFERENCE$"
  WEB_CONTENT_TOKEN = "$IMS_CC_FILEBASE$"
  COURSE_SETTINGS = "course_settings.xml"
  WIKI_FOLDER = 'wiki_content'
  
  def create_key(object, prepend="")
    CCHelper.create_key(object, prepend)
  end
  
  def ims_date(date=nil)
    CCHelper.ims_date(date)
  end
  
  def ims_datetime(date=nil)
    CCHelper.ims_datetime(date)
  end
  
  def self.create_key(object, prepend="")
    if object.is_a? ActiveRecord::Base
      key = object.asset_string
    else
      key = object.to_s
    end
    "i" + Digest::MD5.hexdigest(prepend + key)
  end
  
  def self.ims_date(date=nil)
    date ||= Time.now
    date.strftime(IMS_DATE)
  end
  
  def self.ims_datetime(date=nil)
    date ||= Time.now
    date.strftime(IMS_DATETIME)
  end
end
end