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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe FileInContext do
  before do
    course_model
    folder_model(:name => 'course files')
    @course.folders << @folder
    @course.save!
    @course.reload
  end
  
  context "#attach" do
    it "should create files with the supplied filename escaped for s3" do
      # This horrible hack is because we need Attachment to behave like S3 in this case, as far as filename
      # escaping goes. With attachment_fu, the filename is escaped, without it it is not. Because we're not
      # able to dynamically switch out the S3 status during specs (see the selenium specs that fork a new process
      # to test S3), we fake out just the part we care about. Also, we can't use Mocha because we need the
      # argument of the method. This will be fixed when we've refactored Attachment to allow dynamically
      # switching between S3 and local.
      class Attachment; def filename=(new_name); write_attribute :filename, sanitize_filename(new_name); end; end
      filename = File.expand_path(File.join(File.dirname(__FILE__), %w(.. fixtures files escaping_test[0].txt)))
      attachment = FileInContext.attach(@course, filename, nil, @folder)
      attachment.filename.should == 'escaping_test%5B0%5D.txt'
      class Attachment; undef_method :filename=; end
    end

    it "should close the temp file" do
      # If more than one thread is processing these specs another IO object could
      # be opened. We don't think that should happen so hopefully this won't
      # give any false-fails
      before_count = ObjectSpace.each_object(IO).count {|io| !io.closed?}
      filename = File.expand_path(File.join(File.dirname(__FILE__), %w(.. fixtures files escaping_test[0].txt)))
      attachment = FileInContext.attach(@course, filename, nil, @folder)
      ObjectSpace.each_object(IO).count {|io| !io.closed?}.should == before_count
    end
  end
end
