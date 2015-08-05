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

      new_attachment = @copy_to.attachments.where(migration_id: mig_id(old_attachment)).first
      expect(new_attachment).not_to be_nil
      expect(new_attachment.full_path).to eq "course files/folder_1/folder_2/folder_3/merge.test"
      folder.reload
    end

    it "items in the root folder should be in the root in the new course" do
      att = Attachment.create!(:filename => 'dummy.txt', :uploaded_data => StringIO.new('fakety'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)

      @copy_from.syllabus_body = "<a href='/courses/#{@copy_from.id}/files/#{att.id}/download?wrap=1'>link</a>"
      @copy_from.save!

      run_course_copy

      to_root = Folder.root_folders(@copy_to).first
      new_attachment = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(new_attachment).not_to be_nil
      expect(new_attachment.full_path).to eq "course files/dummy.txt"
      expect(new_attachment.folder).to eq to_root
      expect(@copy_to.syllabus_body).to eq %{<a href="/courses/#{@copy_to.id}/files/#{new_attachment.id}/download?wrap=1">link</a>}
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
        new_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
        expect(new_att.full_path).to eq att.full_path
      end
    end

    it "should add a warning instead of failing when trying to copy an invalid file" do
      att = Attachment.create!(:filename => 'dummy.txt', :uploaded_data => StringIO.new('fakety'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      Attachment.where(:id => att).update_all(:filename => nil)

      att.reload
      expect(att).not_to be_valid

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

      expect(@copy_to.attachments.count).to eq 2
      att_2 = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(att_2).not_to be_nil
      att2_2 = @copy_to.attachments.where(migration_id: mig_id(att2)).first
      expect(att2_2).not_to be_nil

      expect(@copy_to.assignments.first.description).to eq asmnt_des % [@copy_to.id, att_2.id]
      expect(@copy_to.wiki.wiki_pages.first.body).to eq wiki_body % [@copy_to.id, att2_2.id]
    end

    it "should preserve links to re-uploaded attachments" do
      att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att.destroy
      new_att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      expect(@copy_from.attachments.find(att.id)).to eq new_att

      page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => "<a href='/courses/#{@copy_from.id}/files/#{att.id}/download?wrap=1'>link</a>")

      @cm.copy_options = { :wiki_pages => {mig_id(page) => "1"}}
      @cm.save!

      run_course_copy

      att2 = @copy_to.attachments.where(filename: 'first.png').first
      page2 = @copy_to.wiki.wiki_pages.where(migration_id: mig_id(page)).first
      expect(page2.body).to include("<a href=\"/courses/#{@copy_to.id}/files/#{att2.id}/download?wrap=1\">link</a>")
    end

    it "should reference existing usage rights on course copy" do
      usage_rights = @copy_from.usage_rights.create! use_justification: 'used_by_permission', legal_copyright: '(C) 2014 Incom Corp Ltd.'
      att1 = Attachment.create(:filename => '1.txt', :uploaded_data => StringIO.new('1'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att1.usage_rights = usage_rights
      att1.save!
      run_course_copy
      expect(@copy_to.attachments.where(migration_id: mig_id(att1)).first.usage_rights).to eq(usage_rights)
    end

    it "should preserve locked date restrictions on export/import" do
      att = Attachment.create!(:filename => '1.txt', :uploaded_data => StringIO.new('1'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att.unlock_at = 2.days.from_now
      att.lock_at = 3.days.from_now
      att.save!

      run_export_and_import

      copy = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(copy.unlock_at.to_i).to eq att.unlock_at.to_i
      expect(copy.lock_at.to_i).to eq att.lock_at.to_i
    end

    it "should preserve usage rights on export/import" do
      att1 = Attachment.create!(:filename => '1.txt', :uploaded_data => StringIO.new('1'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att2 = Attachment.create!(:filename => '2.txt', :uploaded_data => StringIO.new('2'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att3 = Attachment.create!(:filename => '3.txt', :uploaded_data => StringIO.new('3'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)

      ur1 = @copy_from.usage_rights.create! use_justification: 'used_by_permission', legal_copyright: '(C) 2014 Incom Corp Ltd.'
      ur2 = @copy_from.usage_rights.create! use_justification: 'creative_commons', license: 'cc_by_nd', legal_copyright: '(C) 2014 Koensayr Manufacturing Inc.'
      Attachment.where(id: [att1.id, att2.id]).update_all(usage_rights_id: ur1.id)
      Attachment.where(id: [att3.id]).update_all(usage_rights_id: ur2.id)

      run_export_and_import

      att1_rights = @copy_to.attachments.where(migration_id: mig_id(att1)).first.usage_rights
      att2_rights = @copy_to.attachments.where(migration_id: mig_id(att2)).first.usage_rights
      att3_rights = @copy_to.attachments.where(migration_id: mig_id(att3)).first.usage_rights
      expect(att1_rights).not_to eq(ur1) # check it was actually copied
      expect(att1_rights).to eq(att2_rights) # check de-duplication

      attrs = %w(use_justification legal_copyright license)
      expect(att1_rights.attributes.slice(*attrs)).to eq({"use_justification" => 'used_by_permission', "legal_copyright" => '(C) 2014 Incom Corp Ltd.', "license" => 'private'})
      expect(att3_rights.attributes.slice(*attrs)).to eq({"use_justification" => 'creative_commons', "legal_copyright" => '(C) 2014 Koensayr Manufacturing Inc.', "license" => 'cc_by_nd'})
    end

    describe "usage rights required" do
      def test_usage_rights_over_migration
        attN = Attachment.create!(:filename => 'normal.txt', :uploaded_data => StringIO.new('1'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
        attL = Attachment.create!(:filename => 'locked.txt', :uploaded_data => StringIO.new('2'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from, :locked => true)
        attNU = Attachment.create!(:filename => 'normal+usagerights.txt', :uploaded_data => StringIO.new('3'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
        attLU = Attachment.create!(:filename => 'locked+usagerights.txt', :uploaded_data => StringIO.new('3'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from, :locked => true)
        ur = @copy_from.usage_rights.create! use_justification: 'used_by_permission', legal_copyright: '(C) 2015 Wyndham Systems'
        Attachment.where(id: [attNU.id, attLU.id]).update_all(usage_rights_id: ur.id)

        @copy_to.enable_feature! :usage_rights_required
        yield

        expect(@copy_to.attachments.where(migration_id: mig_id(attN)).first).not_to be_published
        expect(@copy_to.attachments.where(migration_id: mig_id(attL)).first).not_to be_published
        expect(@copy_to.attachments.where(migration_id: mig_id(attNU)).first).to be_published
        expect(@copy_to.attachments.where(migration_id: mig_id(attLU)).first).not_to be_published
      end

      it "should import files as unpublished unless the cartridge provides usage rights" do
        test_usage_rights_over_migration { run_export_and_import }
      end

      it "should import files as unpublished unless the course copy source provides usage rights" do
        test_usage_rights_over_migration { run_course_copy }
      end
    end
  end
end
