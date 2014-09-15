require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy attachments" do
    include_examples "course copy"

    it "should assign the correct parent folder when the parent folder has already been created" do
      folder = Folder.root_folders(@copy_from).first
      folder = folder.sub_folders.create!(:context => @copy_from, :name => 'folder_1')
      att = Attachment.create!(:filename => 'dummy.txt', :uploaded_data => StringIO.new('fakety'), :folder => folder, :context => @copy_from)
      folder = folder.sub_folders.create!(:context => @copy_from, :name => 'folder_2')
      folder = folder.sub_folders.create!(:context => @copy_from, :name => 'folder_3')
      old_attachment = Attachment.create!(:filename => 'merge.test', :uploaded_data => StringIO.new('ohey'), :folder => folder, :context => @copy_from)

      run_course_copy

      new_attachment = @copy_to.attachments.find_by_migration_id(mig_id(old_attachment))
      new_attachment.should_not be_nil
      new_attachment.full_path.should == "course files/folder_1/folder_2/folder_3/merge.test"
      folder.reload
    end

    it "items in the root folder should be in the root in the new course" do
      att = Attachment.create!(:filename => 'dummy.txt', :uploaded_data => StringIO.new('fakety'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)

      @copy_from.syllabus_body = "<a href='/courses/#{@copy_from.id}/files/#{att.id}/download?wrap=1'>link</a>"
      @copy_from.save!

      run_course_copy

      to_root = Folder.root_folders(@copy_to).first
      new_attachment = @copy_to.attachments.find_by_migration_id(mig_id(att))
      new_attachment.should_not be_nil
      new_attachment.full_path.should == "course files/dummy.txt"
      new_attachment.folder.should == to_root
      @copy_to.syllabus_body.should == %{<a href="/courses/#{@copy_to.id}/files/#{new_attachment.id}/download?wrap=1">link</a>}
    end

    it "should copy files into the correct folders when the folders share the same name" do
      root = Folder.root_folders(@copy_from).first
      f1 = root.sub_folders.create!(:name => "folder", :context => @copy_from)
      f2 = f1.sub_folders.create!(:name => "folder", :context => @copy_from)

      atts = []
      atts << Attachment.create!(:filename => 'dummy1.txt', :uploaded_data => StringIO.new('fakety'), :folder => f2, :context => @copy_from)
      atts << Attachment.create!(:filename => 'dummy2.txt', :uploaded_data => StringIO.new('fakety'), :folder => f1, :context => @copy_from)

      run_course_copy

      atts.each do |att|
        new_att = @copy_to.attachments.find_by_migration_id(mig_id(att))
        new_att.full_path.should == att.full_path
      end
    end

    it "should add a warning instead of failing when trying to copy an invalid file" do
      att = Attachment.create!(:filename => 'dummy.txt', :uploaded_data => StringIO.new('fakety'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      Attachment.where(:id => att).update_all(:filename => nil)

      att.reload
      att.should_not be_valid

      run_course_copy(["Couldn't copy file \"dummy.txt\""])
    end

    it "should include implied files for course exports" do
      att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att2 = Attachment.create!(:filename => 'second.jpg', :uploaded_data => StringIO.new('ohais'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att3 = Attachment.create!(:filename => 'third.jpg', :uploaded_data => StringIO.new('3333'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)

      asmnt_des = %{<a href="/courses/%s/files/%s/preview">First file</a>}
      wiki_body = %{<img src="/courses/%s/files/%s/preview">}
      asmnt = @copy_from.assignments.create!(:points_possible => 40, :grading_type => 'points', :description=>(asmnt_des % [@copy_from.id, att.id]), :title => "assignment")
      wiki = @copy_from.wiki.wiki_pages.create!(:title => "wiki", :body => (wiki_body % [@copy_from.id, att2.id]))

      # don't mark the attachments
      @cm.copy_options = {
              :wiki_pages => {mig_id(wiki) => "1"},
              :assignments => {mig_id(asmnt) => "1"},
      }
      @cm.save!
      run_course_copy

      @copy_to.attachments.count.should == 2
      att_2 = @copy_to.attachments.find_by_migration_id(mig_id(att))
      att_2.should_not be_nil
      att2_2 = @copy_to.attachments.find_by_migration_id(mig_id(att2))
      att2_2.should_not be_nil

      @copy_to.assignments.first.description.should == asmnt_des % [@copy_to.id, att_2.id]
      @copy_to.wiki.wiki_pages.first.body.should == wiki_body % [@copy_to.id, att2_2.id]
    end

    it "should preserve links to re-uploaded attachments" do
      att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att.destroy
      new_att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      @copy_from.attachments.find(att.id).should == new_att

      page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => "<a href='/courses/#{@copy_from.id}/files/#{att.id}/download?wrap=1'>link</a>")

      @cm.copy_options = { :wiki_pages => {mig_id(page) => "1"}}
      @cm.save!

      run_course_copy

      att2 = @copy_to.attachments.find_by_filename('first.png')
      page2 = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page))
      page2.body.should include("<a href=\"/courses/#{@copy_to.id}/files/#{att2.id}/download?wrap=1\">link</a>")
    end

  end
end
