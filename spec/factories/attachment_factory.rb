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

Attachment.class_eval do
  # previously we would stub this, but that doesn't play nicely with
  # Marshal.load. since there's only a single spec in the entire suite
  # that wants a non-downloadable attachment, this is going to be a more
  # performant approach
  def downloadable?; true; end

  # fix so we can once-ler attachment instances. in order to
  # Marshal.dump, you can't have any singleton methods (which our
  # Rails 3 attachment_fu hacks do while saving)
  def marshal_dump
    attributes = clone_attributes(:read_attribute_before_type_cast)
    self.class.initialize_attributes(attributes, :serialized => false)
    [attributes, instance_variable_get(:@new_record)]
  end

  def marshal_load(data)
    initialize
    instance_variable_set :@attributes, data[0]
    instance_variable_set :@attributes_cache, {}
    instance_variable_set :@new_record, data[1]
  end
end

def attachment_model(opts={})
  attrs = valid_attachment_attributes(opts).merge(opts)
  attrs.delete(:filename) if attrs.key?(:uploaded_data)
  @attachment = factory_with_protected_attributes(Attachment, attrs, false)
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
  fixture_path = 'test_image.jpg'
  fixture_file_upload(fixture_path, 'image/jpeg', true)
end

def one_hundred_megapixels_of_highly_compressed_png_data
  fixture_path = '100mpx.png'
  fixture_file_upload(fixture_path, 'image/png', true)
end

def crocodocable_attachment_model(opts={})
  attachment_model({:content_type => 'application/pdf'}.merge(opts))
end

alias :canvadocable_attachment_model :crocodocable_attachment_model

def attachment_obj_with_context(obj, opts={})
  @attachment = factory_with_protected_attributes(Attachment, valid_attachment_attributes.merge(opts))
  @attachment.context = obj
  @attachment
end

def attachment_with_context(obj, opts={})
  attachment_obj_with_context(obj, opts)
  @attachment.save!
  @attachment
end

def create_attachment_for_file_upload_submission!(submission, opts={})
  submission.attachments.create! opts.merge({
    :filename => "doc.doc",
    :display_name => "doc.doc", :user => @user,
    :uploaded_data => dummy_io
  })
end
