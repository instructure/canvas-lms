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
  @attachment.stubs(:downloadable?).returns(true)
  @attachment.save!
  @attachment
end
  
def valid_attachment_attributes(opts={})
  @context = opts[:context] || @context || @course || course_model(:reusable => true)
  if opts[:folder]
    folder = opts[:folder]
  else
    if @context.respond_to?(:folders)
      @folder = Folder.root_folders(@context).find{|f| f.name == 'unfiled'} || Folder.root_folders(@context).first
    end
    @folder ||= folder_model
    folder = @folder
  end
  @attributes_res = {
    :context => @context,
    :size => 100,
    :folder => folder,
    :content_type => 'application/loser',
    :filename => 'unknown.loser'
  }
end

def stub_file_data(filename, data, content_type)
  $stub_file_counter ||= 0
  data ||= "ohai#{$stub_file_counter += 1}"
  sio = StringIO.new(data)
  sio.stubs(:original_filename).returns(filename)
  sio.stubs(:content_type).returns(content_type)
  sio
end

def stub_png_data(filename = 'test my file? hai!&.png', data = nil)
  stub_file_data(filename, data, 'image/png')
end

def jpeg_data_frd
  fixture_path = File.expand_path(File.dirname(__FILE__) + '/../fixtures/test_image.jpg')
  ActionController::TestUploadedFile.new(fixture_path, 'image/jpeg', true)
end

# Makes sure we have a value in scribd_mime_types and that the attachment model points to that.
def scribdable_attachment_model(opts={})
  ScribdAPI.stubs(:enabled?).returns(true)
  scribd_mime_type_model(:extension => 'pdf')
  attachment_model({:content_type => 'application/pdf'}.merge(opts))
end

def crocodocable_attachment_model(opts={})
  attachment_model({:content_type => 'application/pdf'}.merge(opts))
end
