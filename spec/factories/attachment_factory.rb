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

def attachment_model(opts={})
  attrs = valid_attachment_attributes(opts).merge(opts)
  attrs.delete(:filename) if attrs.key?(:uploaded_data)
  @attachment = factory_with_protected_attributes(Attachment, attrs, false)
  @attachment.stub!(:downloadable?).and_return(true)
  @attachment.save!
  @attachment
end
  
def valid_attachment_attributes(opts={})
  @context ||= opts[:context] || Course.first || course_model(:reusable => true)
  @folder = Folder.root_folders(@context).find{|f| f.name == 'unfiled'} || Folder.root_folders(@context).first || folder_model
  @attributes_res = {
    :context => @context,
    :size => 100,
    :folder => @folder,
    :content_type => 'application/loser',
    :filename => 'unknown.loser'
  }
end

def stub_png_data(filename = 'test.png', data = nil)
  $stub_file_counter ||= 0
  data ||= "ohai#{$stub_file_counter += 1}"
  sio = StringIO.new(data)
  sio.stub!(:original_filename).and_return(filename)
  sio.stub!(:content_type).and_return('image/png')
  sio
end
