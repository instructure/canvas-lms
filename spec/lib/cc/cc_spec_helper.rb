#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
CC_XML_EXPORT_DIR = File.dirname(__FILE__) + '/../../fixtures/cc/cc_export'

def get_cc_converter
  CC::Importer::Canvas::Converter.new({:no_archive_file=>true})
end

def get_standard_converter
  CC::Importer::Standard::Converter.new({:no_archive_file=>true})
end

def get_cc_export_file(rel_path)
  File.join(CC_XML_EXPORT_DIR, rel_path)
end

def get_ccc_schema
  xsd_filename = File.join(File.expand_path(File.dirname(__FILE__)), '../../../lib/cc/xsd/cccv1p0.xsd')
  Nokogiri::XML::Schema(File.read(xsd_filename))
end
