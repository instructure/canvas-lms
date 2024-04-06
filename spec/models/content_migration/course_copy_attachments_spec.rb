# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "course_copy_helper"

describe ContentMigration do
  context "course copy attachments" do
    include_context "course copy"

    it "assigns the correct parent folder when the parent folder has already been created" do
      folder = Folder.root_folders(@copy_from).first
      folder = folder.sub_folders.create!(context: @copy_from, name: "folder_1")
      Attachment.create!(filename: "dummy.txt", uploaded_data: StringIO.new("fakety"), folder:, context: @copy_from)
      folder = folder.sub_folders.create!(context: @copy_from, name: "folder_2")
      folder = folder.sub_folders.create!(context: @copy_from, name: "folder_3")
      old_attachment = Attachment.create!(filename: "merge.test", uploaded_data: StringIO.new("ohey"), folder:, context: @copy_from)

      run_course_copy

      new_attachment = @copy_to.attachments.where(migration_id: mig_id(old_attachment)).first
      expect(new_attachment).not_to be_nil
      expect(new_attachment.full_path).to eq "course files/folder_1/folder_2/folder_3/merge.test"
      folder.reload
    end

    it "items in the root folder should be in the root in the new course" do
      att = Attachment.create!(filename: "dummy.txt", uploaded_data: StringIO.new("fakety"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)

      @copy_from.syllabus_body = "<a href='/courses/#{@copy_from.id}/files/#{att.id}/download?wrap=1'>link</a>"
      @copy_from.save!

      run_course_copy

      to_root = Folder.root_folders(@copy_to).first
      new_attachment = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(new_attachment).not_to be_nil
      expect(new_attachment.full_path).to eq "course files/dummy.txt"
      expect(new_attachment.folder).to eq to_root
      expect(@copy_to.syllabus_body).to eq %(<a href="/courses/#{@copy_to.id}/files/#{new_attachment.id}/download?wrap=1">link</a>)
    end

    it "copies files into the correct folders when the folders share the same name" do
      root = Folder.root_folders(@copy_from).first
      f1 = root.sub_folders.create!(name: "folder", context: @copy_from)
      f2 = f1.sub_folders.create!(name: "folder", context: @copy_from)

      atts = []
      atts << Attachment.create!(filename: "dummy1.txt", uploaded_data: StringIO.new("fakety"), folder: f2, context: @copy_from)
      atts << Attachment.create!(filename: "dummy2.txt", uploaded_data: StringIO.new("fakety"), folder: f1, context: @copy_from)

      run_course_copy

      atts.each do |att|
        new_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
        expect(new_att.full_path).to eq att.full_path
      end
    end

    it "still copies content in unique_type folders with a name mismatch" do
      root = Folder.root_folders(@copy_from).first
      f1 = root.sub_folders.create!(name: "Uploaded Media", context: @copy_from)
      f2 = Folder.media_folder(@copy_from)
      expect(f2.name).to eq "Uploaded Media 2"
      f1_to = Folder.media_folder(@copy_to) # now create a regularly named media folder

      att1 = Attachment.create!(filename: "dummy1.txt", uploaded_data: StringIO.new("fakety"), folder: f1, context: @copy_from)
      att2 = Attachment.create!(filename: "dummy2.txt", uploaded_data: StringIO.new("fakety"), folder: f2, context: @copy_from)

      run_course_copy

      f2_to = @copy_to.folders.where(name: f2.name).first
      expect(f2_to.unique_type).to be_nil # because it's already taken by f1_to

      att1_to = @copy_to.attachments.where(migration_id: mig_id(att1)).first
      att2_to = @copy_to.attachments.where(migration_id: mig_id(att2)).first
      expect(att1_to.folder).to eq f1_to
      expect(att2_to.folder).to eq f2_to
    end

    it "adds a warning instead of failing when trying to copy an invalid file" do
      att = Attachment.create!(filename: "dummy.txt", uploaded_data: StringIO.new("fakety"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      Attachment.where(id: att).update_all(filename: nil)

      att.reload
      expect(att).not_to be_valid

      run_course_copy(["Couldn't copy file \"dummy.txt\""])
    end

    it "includes implied files for course exports" do
      att = Attachment.create!(filename: "first.png", uploaded_data: StringIO.new("ohai"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      att2 = Attachment.create!(filename: "second.jpg", uploaded_data: StringIO.new("ohais"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      Attachment.create!(filename: "third.jpg", uploaded_data: StringIO.new("3333"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)

      asmnt_des = %(<a href="/courses/%s/files/%s/preview">First file</a>)
      wiki_body = %(<img src="/courses/%s/files/%s/preview">)
      asmnt = @copy_from.assignments.create!(points_possible: 40, grading_type: "points", description: (asmnt_des % [@copy_from.id, att.id]), title: "assignment")
      wiki = @copy_from.wiki_pages.create!(title: "wiki", body: (wiki_body % [@copy_from.id, att2.id]))

      # don't mark the attachments
      @cm.copy_options = {
        wiki_pages: { mig_id(wiki) => "1" },
        assignments: { mig_id(asmnt) => "1" },
      }
      @cm.save!
      run_course_copy

      expect(@copy_to.attachments.count).to eq 2
      att_2 = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(att_2).not_to be_nil
      att2_2 = @copy_to.attachments.where(migration_id: mig_id(att2)).first
      expect(att2_2).not_to be_nil

      expect(@copy_to.assignments.first.description).to eq asmnt_des % [@copy_to.id, att_2.id]
      expect(@copy_to.wiki_pages.first.body).to eq wiki_body % [@copy_to.id, att2_2.id]
    end

    it "preserves links to re-uploaded attachments" do
      att = Attachment.create!(filename: "first.png", uploaded_data: StringIO.new("ohai"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      att.destroy
      new_att = Attachment.create!(filename: "first.png", uploaded_data: StringIO.new("ohai"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      expect(@copy_from.attachments.find(att.id)).to eq new_att

      page = @copy_from.wiki_pages.create!(title: "some page", body: "<a href='/courses/#{@copy_from.id}/files/#{att.id}/download?wrap=1'>link</a>")

      @cm.copy_options = { wiki_pages: { mig_id(page) => "1" } }
      @cm.save!

      run_course_copy

      att2 = @copy_to.attachments.where(filename: "first.png").first
      page2 = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      expect(page2.body).to include("<a href=\"/courses/#{@copy_to.id}/files/#{att2.id}/download?wrap=1\">link</a>")
    end

    it "updates RCE mediahref iframes to media_attachment_iframes" do
      att = @copy_from.attachments.create!(filename: "videro.mov", uploaded_data: StringIO.new("..."), folder: Folder.root_folders(@copy_from).first)
      page = @copy_from.wiki_pages.create!(title: "watch this y'all", body: %(<iframe data-media-type="video" src="/media_objects_iframe?mediahref=/courses/#{@copy_from.id}/files/#{att.id}/download" data-media-id="#{att.id}"/>))
      run_course_copy
      att_to = @copy_to.attachments.where(migration_id: mig_id(att)).take
      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).take
      expect(page_to.body).to include %(src="/media_attachments_iframe/#{att_to.id}?type=video&embedded=true")
    end

    it "references existing usage rights on course copy" do
      usage_rights = @copy_from.usage_rights.create! use_justification: "used_by_permission", legal_copyright: "(C) 2014 Incom Corp Ltd."
      att1 = Attachment.create(filename: "1.txt", uploaded_data: StringIO.new("1"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      att1.usage_rights = usage_rights
      att1.save!
      run_course_copy
      expect(@copy_to.attachments.where(migration_id: mig_id(att1)).first.usage_rights).to eq(usage_rights)
    end

    it "preserves 'category' on export/import" do
      att = Attachment.create!(
        filename: "1.txt",
        uploaded_data: StringIO.new("1"),
        folder: Folder.root_folders(@copy_from).first,
        context: @copy_from,
        category: Attachment::ICON_MAKER_ICONS
      )

      run_export_and_import

      copy = @copy_to.attachments.find_by(migration_id: mig_id(att))
      expect(copy.category).to eq Attachment::ICON_MAKER_ICONS
    end

    it "preserves locked date restrictions on export/import" do
      att = Attachment.create!(filename: "1.txt",
                               uploaded_data: StringIO.new("1"),
                               folder: Folder.root_folders(@copy_from).first,
                               context: @copy_from)
      att.unlock_at = 2.days.from_now
      att.lock_at = 3.days.from_now
      att.save!

      run_export_and_import

      copy = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(copy.unlock_at.to_i).to eq att.unlock_at.to_i
      expect(copy.lock_at.to_i).to eq att.lock_at.to_i
    end

    it "preserves terrible folder names on export/import" do
      root = Folder.root_folders(@copy_from).first
      sub = root.sub_folders.create!(name: ".sadness", context: @copy_from)

      att = Attachment.create!(filename: "1.txt", uploaded_data: StringIO.new("1"), folder: sub, context: @copy_from)

      run_export_and_import

      copy_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(copy_att.filename).to eq "1.txt"
      copy_sub = copy_att.folder
      expect(copy_sub.name).to eq ".sadness"
    end

    it "preserves module items for hidden files on course copy" do
      att = Attachment.create!(filename: "1.txt", uploaded_data: StringIO.new("1"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      att.hidden = true
      att.save!

      mod = @copy_from.context_modules.create!(name: "some module")
      mod.add_item({ id: att.id, type: "attachment" })

      run_course_copy

      copy_att = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(copy_att.hidden).to be_truthy

      copy_mod = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
      copy_tag = copy_mod.content_tags.first
      expect(copy_tag.content).to eq copy_att
    end

    it "preserves usage rights on export/import" do
      att1 = Attachment.create!(filename: "1.txt", uploaded_data: StringIO.new("1"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      att2 = Attachment.create!(filename: "2.txt", uploaded_data: StringIO.new("2"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
      att3 = Attachment.create!(filename: "3.txt", uploaded_data: StringIO.new("3"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)

      ur1 = @copy_from.usage_rights.create! use_justification: "used_by_permission", legal_copyright: "(C) 2014 Incom Corp Ltd."
      ur2 = @copy_from.usage_rights.create! use_justification: "creative_commons", license: "cc_by_nd", legal_copyright: "(C) 2014 Koensayr Manufacturing Inc."
      Attachment.where(id: [att1.id, att2.id]).update_all(usage_rights_id: ur1.id)
      Attachment.where(id: [att3.id]).update_all(usage_rights_id: ur2.id)

      run_export_and_import

      att1_rights = @copy_to.attachments.where(migration_id: mig_id(att1)).first.usage_rights
      att2_rights = @copy_to.attachments.where(migration_id: mig_id(att2)).first.usage_rights
      att3_rights = @copy_to.attachments.where(migration_id: mig_id(att3)).first.usage_rights
      expect(att1_rights).not_to eq(ur1) # check it was actually copied
      expect(att1_rights).to eq(att2_rights) # check de-duplication

      attrs = %w[use_justification legal_copyright license]
      expect(att1_rights.attributes.slice(*attrs)).to eq({ "use_justification" => "used_by_permission", "legal_copyright" => "(C) 2014 Incom Corp Ltd.", "license" => "private" })
      expect(att3_rights.attributes.slice(*attrs)).to eq({ "use_justification" => "creative_commons", "legal_copyright" => "(C) 2014 Koensayr Manufacturing Inc.", "license" => "cc_by_nd" })
    end

    describe "usage rights required" do
      before do
        @copy_from.account.settings[:usage_rights_required] = true
        @copy_from.account.save!
      end

      def test_usage_rights_over_migration
        attN = Attachment.create!(filename: "normal.txt", uploaded_data: StringIO.new("1"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
        attL = Attachment.create!(filename: "locked.txt", uploaded_data: StringIO.new("2"), folder: Folder.root_folders(@copy_from).first, context: @copy_from, locked: true)
        attNU = Attachment.create!(filename: "normal+usagerights.txt", uploaded_data: StringIO.new("3"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
        attLU = Attachment.create!(filename: "locked+usagerights.txt", uploaded_data: StringIO.new("3"), folder: Folder.root_folders(@copy_from).first, context: @copy_from, locked: true)
        ur = @copy_from.usage_rights.create! use_justification: "used_by_permission", legal_copyright: "(C) 2015 Wyndham Systems"
        Attachment.where(id: [attNU.id, attLU.id]).update_all(usage_rights_id: ur.id)

        yield

        expect(@copy_to.attachments.where(migration_id: mig_id(attN)).first).not_to be_published
        expect(@copy_to.attachments.where(migration_id: mig_id(attL)).first).not_to be_published
        expect(@copy_to.attachments.where(migration_id: mig_id(attNU)).first).to be_published
        expect(@copy_to.attachments.where(migration_id: mig_id(attLU)).first).not_to be_published
      end

      it "imports files as published if the parent course does not require usage rights" do
        @copy_from.usage_rights_required = false

        @copy_from.save!
        @copy_to.save!

        att = Attachment.create!(filename: "normal.txt", uploaded_data: StringIO.new("1"), folder: Folder.root_folders(@copy_from).first, context: @copy_from)
        run_course_copy
        expect(@copy_to.attachments.where(migration_id: mig_id(att)).first).to be_published
      end

      it "imports files as published if the cartridge provides usage rights" do
        test_usage_rights_over_migration { run_export_and_import }
      end

      it "imports files as published i the course copy source provides usage rights" do
        test_usage_rights_over_migration { run_course_copy }
      end
    end
  end
end
