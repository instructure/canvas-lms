# coding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe Attachment do
  context "validation" do
    it "should create a new instance given valid attributes" do
      attachment_model
    end

    it "should require a context" do
      expect{attachment_model(:context => nil)}.to raise_error(ActiveRecord::RecordInvalid, /Context/)
    end

  end

  context "default_values" do
    before :once do
      @course = course_model
    end

    it "should set the display name to the filename if it is nil" do
      attachment_model(:display_name => nil)
      expect(@attachment.display_name).to eql(@attachment.filename)
    end

  end

  context "public_url" do
    before :each do
      local_storage!
    end

    before :once do
      course_model
    end

    it "should return http as the protocol by default" do
      attachment_with_context(@course)
      expect(@attachment.public_url).to match(/^http:\/\//)
    end

    it "should return the protocol if specified" do
      attachment_with_context(@course)
      expect(@attachment.public_url(:secure => true)).to match(/^https:\/\//)
    end

    context "for a quiz submission upload" do
      it "should return a routable url", :type => :routing do
        quiz = @course.quizzes.create
        submission = Quizzes::SubmissionManager.new(quiz).find_or_create_submission(user_model)
        attachment = attachment_with_context(submission)
        expect(get(attachment.public_url)).to be_routable
      end
    end
  end

  context "public_url InstFS storage" do
    before :once do
      user_model
    end

    before :each do
      attachment_with_context(@user)
      @attachment.instfs_uuid = 1
      allow(InstFS).to receive(:enabled?).and_return true
      allow(InstFS).to receive(:authenticated_url)
    end

    it "should get url from InstFS when attachment has instfs_uuid" do
      @attachment.public_url
      expect(InstFS).to have_received(:authenticated_url)
    end

    it "should still get url from InstFS when attachment has instfs_uuid and instfs is later disabled" do
      allow(InstFS).to receive(:enabled?).and_return false
      @attachment.public_url
      expect(InstFS).to have_received(:authenticated_url)
    end

    it "should not get url from InstFS when instfs is enabled but attachment lacks instfs_uuid" do
      @attachment.instfs_uuid = nil
      @attachment.public_url
      expect(InstFS).not_to have_received(:authenticated_url)
    end
  end

  context "public_url s3_storage" do
    before :each do
      s3_storage!
    end

    it "should give back a signed s3 url" do
      a = attachment_model
      s3object = a.s3object
      expect(a.public_url(expires_in: 1.day)).to match(/^https:\/\//)
      a.destroy_permanently!
    end
  end

  def configure_crocodoc
    PluginSetting.create! :name => 'crocodoc',
                          :settings => { :api_key => "blahblahblahblahblah" }
    allow_any_instance_of(Crocodoc::API).to receive(:upload).and_return 'uuid' => '1234567890'
  end

  def configure_canvadocs(opts = {})
    ps = PluginSetting.where(name: "canvadocs").first_or_create
    ps.update_attribute :settings, {
      "api_key" => "blahblahblahblahblah",
      "base_url" => "http://example.com",
      "annotations_supported" => true
    }.merge(opts)
  end

  context "crocodoc" do
    include HmacHelper
    let_once(:user) { user_model }
    let_once(:course) { course_model }
    let_once(:student) do
      course.enroll_student(user_model).accept
      @user
    end
    before { configure_crocodoc }

    it "crocodocable?" do
      crocodocable_attachment_model
      expect(@attachment).to be_crocodocable
    end

    it "should include a whitelist of moderated_grading_whitelist in the url blob" do
      crocodocable_attachment_model
      moderated_grading_whitelist = [user, student].map { |u| u.moderated_grading_ids(true) }

      @attachment.submit_to_crocodoc
      url_opts = {
        moderated_grading_whitelist: moderated_grading_whitelist
      }
      url = Rack::Utils.parse_nested_query(@attachment.crocodoc_url(user, url_opts).sub(/^.*\?{1}/, ""))
      blob = extract_blob(url["hmac"], url["blob"],
                          "user_id" => user.id,
                          "type" => "crocodoc")

      expect(blob["moderated_grading_whitelist"]).to include(user.moderated_grading_ids.as_json)
      expect(blob["moderated_grading_whitelist"]).to include(student.moderated_grading_ids.as_json)
    end

    it "should always enable annotations when creating a crocodoc url" do
      crocodocable_attachment_model
      @attachment.submit_to_crocodoc

      url = Rack::Utils.parse_nested_query(@attachment.crocodoc_url(user, {}).sub(/^.*\?{1}/, ""))
      blob = extract_blob(url["hmac"], url["blob"],
                          "user_id" => user.id,
                          "type" => "crocodoc")

      expect(blob["enable_annotations"]).to be(true)
    end

    it "should not modify the options reference given to create a crocodoc url" do
      crocodocable_attachment_model
      @attachment.submit_to_crocodoc

      url_opts = {}
      @attachment.crocodoc_url(user, url_opts)
      expect(url_opts).to eql({})
    end

    it "should submit to crocodoc" do
      crocodocable_attachment_model
      expect(@attachment.crocodoc_available?).to be_falsey
      @attachment.submit_to_crocodoc

      expect(@attachment.crocodoc_available?).to be_truthy
      expect(@attachment.crocodoc_document.uuid).to eq '1234567890'
    end

    it "should spawn delayed jobs to retry failed uploads" do
      allow_any_instance_of(Crocodoc::API).to receive(:upload).and_return 'error' => 'blah'
      crocodocable_attachment_model

      attempts = 3
      Setting.set('max_crocodoc_attempts', attempts)

      track_jobs do
        # first attempt
        @attachment.submit_to_crocodoc

        time = Time.now
        # nth attempt won't create more jobs
        attempts.times {
          time += 1.hour
          Timecop.freeze(time) do
            run_jobs
          end
        }
      end

      expect(created_jobs.size).to eq attempts
    end

    it "should submit to canvadocs if crocodoc fails to convert" do
      crocodocable_attachment_model
      @attachment.submit_to_crocodoc

      allow_any_instance_of(Crocodoc::API).to receive(:status).and_return [
        {'uuid' => '1234567890', 'status' => 'ERROR'}
      ]
      allow(Canvadocs).to receive(:enabled?).and_return true

      expects_job_with_tag('Attachment.submit_to_canvadocs') {
        CrocodocDocument.update_process_states
      }
    end
  end

  context "canvadocs" do
    before :once do
      configure_canvadocs
    end

    before :each do
      allow_any_instance_of(Canvadocs::API).to receive(:upload).and_return "id" => 1234
    end

    it "should treat text files equally" do
      a = attachment_model(:content_type => 'text/x-ruby-script')
      allow(Canvadoc).to receive(:mime_types).and_return(['text/plain'])
      expect(a.canvadocable?).to be_truthy
    end

    describe "submit_to_canvadocs" do
      it "submits canvadocable documents" do
        a = canvadocable_attachment_model
        a.submit_to_canvadocs
        expect(a.canvadoc.document_id).not_to be_nil
      end

      it "works from the bulk uploader" do
        a1 = canvadocable_attachment_model
        Attachment.submit_to_canvadocs([a1.id])
        expect(a1.canvadoc.document_id).not_to be_nil
      end

      it "doesn't submit non-canvadocable documents" do
        a = attachment_model
        a.submit_to_canvadocs
        expect(a.canvadoc).to be_nil
      end

      it "tries again later when upload fails" do
        allow_any_instance_of(Canvadocs::API).to receive(:upload).and_return(nil)
        expects_job_with_tag('Attachment#submit_to_canvadocs') {
          canvadocable_attachment_model.submit_to_canvadocs
        }
      end

      it "sends annotatable documents to canvadocs if supported" do
        configure_crocodoc
        a = crocodocable_attachment_model
        a.submit_to_canvadocs 1, wants_annotation: true
        expect(a.canvadoc).not_to be_nil
      end

      it "prefers crocodoc when annotation is requested and canvadocs can't annotate" do
        configure_crocodoc
        configure_canvadocs "annotations_supported" => false
        Setting.set('canvadoc_mime_types',
                    (Canvadoc.mime_types << "application/blah").to_json)

        crocodocable = crocodocable_attachment_model
        canvadocable = canvadocable_attachment_model content_type: "application/blah"

        crocodocable.submit_to_canvadocs 1, wants_annotation: true
        run_jobs
        expect(crocodocable.canvadoc).to be_nil
        expect(crocodocable.crocodoc_document).not_to be_nil

        canvadocable.submit_to_canvadocs 1, wants_annotation: true
        expect(canvadocable.canvadoc).not_to be_nil
        expect(canvadocable.crocodoc_document).to be_nil
      end
    end
  end

  it "should set the uuid" do
    attachment_model
    expect(@attachment.uuid).not_to be_nil
  end

  context "workflow" do
    before :once do
      attachment_model
    end

    it "should default to pending_upload" do
      expect(@attachment.state).to eql(:pending_upload)
    end

    it "should be able to take a processing object and complete its process" do
      attachment_model(:workflow_state => 'processing')
      @attachment.process!
      expect(@attachment.state).to eql(:processed)
    end

    it "should be able to take a new object and bypass upload with process" do
      @attachment.process!
      expect(@attachment.state).to eql(:processed)
    end

    it "should be able to recycle a processed object and re-upload it" do
      attachment_model(:workflow_state => 'processed')
      @attachment.recycle
      expect(@attachment.state).to eql(:pending_upload)
    end
  end

  context "named scopes" do
    context "by_content_types" do
      before :once do
        course_model
        @gif = attachment_model :context => @course, :content_type => 'image/gif'
        @jpg = attachment_model :context => @course, :content_type => 'image/jpeg'
        @weird = attachment_model :context => @course, :content_type => "%/what's this"
      end

      it "should match type" do
        expect(@course.attachments.by_content_types(['image']).pluck(:id).sort).to eq [@gif.id, @jpg.id].sort
      end

      it "should match type/subtype" do
        expect(@course.attachments.by_content_types(['image/gif']).pluck(:id)).to eq [@gif.id]
        expect(@course.attachments.by_content_types(['image/gif', 'image/jpeg']).pluck(:id).sort).to eq [@gif.id, @jpg.id].sort
      end

      it "should escape sql and wildcards" do
        expect(@course.attachments.by_content_types(['%']).pluck(:id)).to eq [@weird.id]
        expect(@course.attachments.by_content_types(["%/what's this"]).pluck(:id)).to eq [@weird.id]
        expect(@course.attachments.by_content_types(["%/%"]).pluck(:id)).to eq []
      end
    end
  end

  context "uploaded_data" do
    it "should create with uploaded_data" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      expect(a.filename).to eql("doc.doc")
    end

    context "uploading and db transactions" do
      before :once do
        attachment_model(:context => Account.default.groups.create!, :filename => 'test.mp4', :content_type => 'video')
      end

      it "should delay upload until the #save transaction is committed" do
        allow(Rails.env).to receive(:test?).and_return(false)
        @attachment.uploaded_data = default_uploaded_data
        expect(Attachment.connection).to receive(:after_transaction_commit).twice
        expect(@attachment).to receive(:touch_context_if_appropriate).never
        expect(@attachment).to receive(:ensure_media_object).never
        @attachment.save
      end
    end
  end

  context "ensure_media_object" do
    before :once do
      @course = course_factory
      @attachment = @course.attachments.build(:filename => 'foo.mp4')
      @attachment.content_type = 'video'
    end

    it "should be called automatically upon creation" do
      expect(@attachment).to receive(:ensure_media_object).once
      @attachment.save!
    end

    it "should create a media object for videos" do
      @attachment.update_attribute(:media_entry_id, 'maybe')
      expect(@attachment).to receive(:build_media_object).once.and_return(true)
      @attachment.save!
    end

    it "should delay the creation of the media object by attachment_build_media_object_delay_seconds" do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)
      allow(Setting).to receive(:get).and_return(nil)
      expect(Setting).to receive(:get).with('attachment_build_media_object_delay_seconds', '10').once.and_return('25')
      track_jobs do
        @attachment.save!
      end

      expect(MediaObject.count).to eq 0
      job = created_jobs.first
      expect(job.tag).to eq 'MediaObject.add_media_files'
      expect(job.run_at.to_i).to eq (now + 25.seconds).to_i
    end

    it "should not create a media object in a skip_media_object_creation block" do
      Attachment.skip_media_object_creation do
        expect(@attachment).to receive(:build_media_object).never
        @attachment.save!
      end
    end

    it "should not create a media object for images" do
      @attachment.filename = 'foo.png'
      @attachment.content_type = 'image/png'
      expect(@attachment).to receive(:ensure_media_object).once
      expect(@attachment).to receive(:build_media_object).never
      @attachment.save!
    end

    it "should create a media object *after* a direct-to-s3 upload" do
      allowed = false
      expect(@attachment).to receive(:build_media_object) do
        raise "not allowed" unless allowed
      end
      @attachment.workflow_state = 'unattached'
      @attachment.file_state = 'deleted'
      @attachment.save!
      allowed = true
      @attachment.workflow_state = nil
      @attachment.file_state = 'available'
      @attachment.save!
    end

    it "should disassociate but not delete the associated media object" do
      @attachment.media_entry_id = '0_feedbeef'
      @attachment.save!

      media_object = @course.media_objects.build :media_id => '0_feedbeef'
      media_object.attachment_id = @attachment.id
      media_object.save!

      @attachment.destroy

      media_object.reload
      expect(media_object).not_to be_deleted
      expect(media_object.attachment_id).to be_nil
    end
  end

  context "destroy" do
    it "should not actually destroy" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      expect(a.filename).to eql("doc.doc")
      a.destroy
      expect(a).not_to be_frozen
      expect(a).to be_deleted
    end

    it "should not probably be possible to actually destroy... somehow" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      expect(a.filename).to eql("doc.doc")
      a.destroy
      expect(a).not_to be_frozen
      expect(a).to be_deleted
      a.destroy_permanently!
      expect(a).to be_frozen
    end

    it "should not show up in the context list after being destroyed" do
      @course = course_factory
      expect(@course).not_to be_nil
      a = attachment_model(:uploaded_data => default_uploaded_data, :context => @course)
      expect(a.filename).to eql("doc.doc")
      expect(a.context).to eql(@course)
      a.destroy
      expect(a).not_to be_frozen
      expect(a).to be_deleted
      expect(@course.attachments).to be_include(a)
      expect(@course.attachments.active).not_to be_include(a)
    end

    it "should still destroy without error if file data is lost" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      allow(a).to receive(:downloadable?).and_return(false)
      a.destroy
      expect(a).to be_deleted
    end

    it "should replace uploaded data on destroy_content_and_replace" do
      a = attachment_model(uploaded_data: default_uploaded_data)
      expect(a.content_type).to eq 'application/msword'
      a.destroy_content_and_replace
      expect(a.content_type).to eq 'application/pdf'
    end

    it "should also destroy thumbnails" do
      a = attachment_model(uploaded_data: stub_png_data, content_type: 'image/png')
      thumb = a.thumbnail
      expect(thumb).not_to be_nil
      expect(thumb).to receive(:destroy).once
      a.destroy_content_and_replace
    end

    it "should destroy content and record on destroy_permanently_plus" do
      a = attachment_model
      a2 = attachment_model(root_attachment: a)
      expect(a).to receive(:make_childless).once
      expect(a).to receive(:destroy_content).once
      expect(a2).to receive(:make_childless).never
      expect(a2).to receive(:destroy_content).never
      a2.destroy_permanently_plus
      a.destroy_permanently_plus
      expect { a.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { a2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should not delete s3objects if it is not production for destroy_content' do
      allow(ApplicationController).to receive(:test_cluster?).and_return(true)
      s3_storage!
      a = attachment_model
      allow(a).to receive(:s3object).and_return(double('s3object'))
      s3object = a.s3object
      expect(s3object).to receive(:delete).never
      a.destroy_content
    end

    it 'should allow destroy_content_and_replace when s3object is already deleted' do
      s3_storage!
      a = attachment_model(uploaded_data: default_uploaded_data)
      a.s3object.delete
      a.destroy_content_and_replace
      expect(Purgatory.where(attachment_id: a.id).exists?).to be_truthy
    end

    it 'should not do destroy_content_and_replace twice' do
      a = attachment_model(uploaded_data: default_uploaded_data)
      a.destroy_content_and_replace # works
      expect(a).to receive(:send_to_purgatory).never
      a.destroy_content_and_replace # returns because it already happened
    end

    it 'should destroy all crocodocs even from children attachments' do
      local_storage!
      configure_crocodoc

      a = crocodocable_attachment_model(uploaded_data: default_uploaded_data)
      a2 = attachment_model(root_attachment: a)
      a2.submit_to_canvadocs 1, wants_annotation: true
      a.submit_to_canvadocs 1, wants_annotation: true
      run_jobs

      expect(a.crocodoc_document).not_to be_nil
      expect(a2.crocodoc_document).not_to be_nil
      a.destroy_content_and_replace
      expect(a.reload.crocodoc_document).to be_nil
      expect(a2.reload.crocodoc_document).to be_nil
    end

    it 'should allow destroy_content_and_replace on children attachments' do
      a = attachment_model(uploaded_data: default_uploaded_data)
      a2 = attachment_model(root_attachment: a)
      a2.destroy_content_and_replace
      purgatory = Purgatory.where(attachment_id: [a.id, a2.id])
      expect(purgatory.count).to eq 1
      expect(purgatory.take.attachment_id).to eq a.id
    end

    shared_examples_for "purgatory" do
      it 'should save file in purgatory and then restore and back again' do
        a = attachment_model(uploaded_data: default_uploaded_data)
        old_filename = a.filename
        old_content_type = a.content_type
        a.destroy_content_and_replace
        purgatory = Purgatory.where(attachment_id: a).take
        expect(purgatory.old_filename).to eq old_filename
        expect(purgatory.old_display_name).to eq old_filename
        expect(purgatory.old_content_type).to eq old_content_type
        a.reload
        expect(a.filename).to eq 'file_removed.pdf'
        expect(a.display_name).to eq 'file_removed.pdf'
        a.resurrect_from_purgatory
        a.reload
        expect(a.filename).to eq old_filename
        expect(a.display_name).to eq old_filename
        expect(a.content_type).to eq old_content_type
        expect(purgatory.reload.workflow_state).to eq 'restored'
        a.destroy_content_and_replace
        expect(purgatory.reload.workflow_state).to eq 'active'
      end
    end

    context "s3" do
      include_examples "purgatory"
      before { s3_storage! }
    end

    context "s3" do
      include_examples "purgatory"
      before { local_storage! }
    end
  end

  context "restore" do
    it "should restore to 'available' state" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      a.destroy
      expect(a).to be_deleted
      a.restore
      expect(a).to be_available
    end
  end

  context "destroy_permanently!" do
    it "should not delete the s3 object, even here" do
      s3_storage!
      a = attachment_model
      s3object = a.s3object
      expect(s3object).to receive(:delete).never
      a.destroy_permanently!
    end
  end

  context "inferred display name" do
    before do
      s3_storage!  # because we don't 'sanitize' filenames with the local backend
    end

    it "should take a normal filename and use it as a diplay name" do
      a = attachment_model(:filename => 'normal_name.ppt')
      expect(a.display_name).to eql('normal_name.ppt')
      expect(a.filename).to eql('normal_name.ppt')
    end

    it "should preserve case" do
      a = attachment_model(:filename => 'Normal_naMe.ppt')
      expect(a.display_name).to eql('Normal_naMe.ppt')
      expect(a.filename).to eql('Normal_naMe.ppt')
    end

    it "should truncate filenames to 255 characters (preserving extension)" do
      a = attachment_model(:filename => 'My new study guide or case study on this evolution on monkeys even in that land of costa rica somewhere my own point of  view going along with the field experiment I would say or try out is to put them not in wet areas like costa rico but try and put it so its not so long.docx')
      expect(a.display_name).to eql("My new study guide or case study on this evolution on monkeys even in that land of costa rica somewhere my own point of  view going along with the field experiment I would say or try out is to put them not in wet areas like costa rico but try and put.docx")
      expect(a.filename).to eql("My+new+study+guide+or+case+study+on+this+evolution+on+monkeys+even+in+that+land+of+costa+rica+somewhere+my+own+point+of++view+going+along+with+the+field+experiment+I+would+say+or+try+out+is+to+put+them+not+in+wet+areas+like+costa+rico+but+try+and+put.docx")
    end

    it "should use no more than half of the 255 characters for the extension" do
      a = attachment_model(:filename => ("A" * 150) + "." + ("B" * 150))
      expect(a.display_name).to eql(("A" * 127) + "." + ("B" * 127))
      expect(a.filename).to eql(("A" * 127) + "." + ("B" * 127))
    end

    it "should not split unicode characters when truncating" do
      a = attachment_model(:filename => "\u2603" * 300)
      expect(a.display_name).to eql("\u2603" * 255)
      expect(a.filename.length).to eql(252)
      expect(a.unencoded_filename).to be_valid_encoding
      expect(a.unencoded_filename).to eql("\u2603" * 28)
    end

    it "should truncate thumbnail names" do
      a = attachment_model(:filename => "#{"a" * 251}.png")
      thumbname = a.thumbnail_name_for("thumb")
      expect(thumbname.length).to eq 255
      expect(thumbname).to eq "#{"a" * 245}_thumb.png"
    end

    it "should not double-escape a root attachment's filename" do
      a = attachment_model(:filename => 'something with spaces.txt')
      expect(a.filename).to eq 'something+with+spaces.txt'
      a2 = Attachment.new
      a2.root_attachment = a
      expect(a2.sanitize_filename(nil)).to eq a.filename
    end
  end

  context "clone_for" do
    it "should clone to another context" do
      a = attachment_model(:filename => "blech.ppt")
      course_factory
      new_a = a.clone_for(@course)
      expect(new_a.context).not_to eql(a.context)
      expect(new_a.filename).to eql(a.filename)
      expect(new_a.read_attribute(:filename)).to be_nil
      expect(new_a.root_attachment_id).to eql(a.id)
    end

    it "should clone to another root_account" do
      c = course_factory
      a = attachment_model(filename: "blech.ppt", context: c)
      new_account = Account.create
      c2 = course_factory(account: new_account)
      allow(Attachment).to receive(:s3_storage?).and_return(true)
      expect_any_instance_of(Attachment).to receive(:make_rootless).once
      expect_any_instance_of(Attachment).to receive(:change_namespace).once
      a2 = a.clone_for(c2)
    end

    it "should create thumbnails for images on clone" do
      c = course_factory
      a = attachment_model(filename: "blech.jpg", context: c, content_type: 'image/jpg')
      new_account = Account.create
      c2 = course_factory(account: new_account)
      allow(Attachment).to receive(:s3_storage?).and_return(true)
      expect_any_instance_of(Attachment).to receive(:copy_attachment_content).once
      expect_any_instance_of(Attachment).to receive(:change_namespace).once
      expect_any_instance_of(Attachment).to receive(:create_thumbnail_size).once
      a2 = a.clone_for(c2)
    end

    it "should link the thumbnail" do
      a = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
      expect(a.thumbnail).not_to be_nil
      course_factory
      new_a = a.clone_for(@course)
      expect(new_a.thumbnail).not_to be_nil
      expect(new_a.thumbnail_url).not_to be_nil
      expect(new_a.thumbnail_url).to eq a.thumbnail_url
    end

    it "should not create root_attachment_id cycles or self-references" do
      a = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
      expect(a.root_attachment_id).to be_nil
      coursea = @course
      @context = courseb = course_factory
      b = a.clone_for(courseb, nil, :overwrite => true)
      b.save
      expect(b.context).to eq courseb
      expect(b.root_attachment).to eq a

      new_a = b.clone_for(coursea, nil, :overwrite => true)
      expect(new_a).to eq a
      expect(new_a.root_attachment_id).to be_nil

      new_b = new_a.clone_for(courseb, nil, :overwrite => true)
      expect(new_b.root_attachment_id).to eq a.id

      new_b = b.clone_for(courseb, nil, :overwrite => true)
      expect(new_b.root_attachment_id).to eq a.id

      @context = coursec = course_factory
      c = b.clone_for(coursec, nil, :overwrite => true)
      expect(c.root_attachment).to eq a

      new_a = c.clone_for(coursea, nil, :overwrite => true)
      expect(new_a).to eq a
      expect(new_a.root_attachment_id).to be_nil

      # pretend b's content changed so it got disconnected
      b.update_attribute(:root_attachment_id, nil)
      new_b = b.clone_for(courseb, nil, :overwrite => true)
      expect(new_b.root_attachment_id).to be_nil
    end

    it "should set correct namespace across clones" do
      s3_storage!
      a = attachment_model
      expect(a.root_attachment_id).to be_nil
      coursea = @course
      @context = courseb = course_factory(account: Account.create)

      b = a.clone_for(courseb, nil, overwrite: true)
      expect(b.id).not_to be_nil
      expect(b.filename).to eq a.filename
      b.save
      expect(b.root_attachment_id).to eq nil
      expect(b.namespace).to eq courseb.root_account.file_namespace

      new_a = b.clone_for(coursea, nil, overwrite: true)
      new_a.save
      expect(new_a).to eq a
      expect(new_a.namespace).to eq coursea.root_account.file_namespace
    end
  end

  context "adheres_to_policy" do
    let_once(:user) { user_model }
    let_once(:course) do
      course_model
      @course.offer
      @course.update_attribute(:is_public, false)
      @course
    end
    let_once(:student) do
      course.enroll_student(user_model).accept
      @user
    end
    let_once(:attachment) do
      attachment_model(context: course)
    end

    it "should not allow unauthorized users to read files" do
      a = attachment_model(context: course_model)
      @course.update_attribute(:is_public, false)
      expect(a.grants_right?(user, :read)).to eql(false)
    end

    it "should allow anonymous access for public contexts" do
      a = attachment_model(context: course_model)
      @course.update_attribute(:is_public, true)
      expect(a.grants_right?(user, :read)).to eql(false)
    end

    it "should allow students to read files" do
      a = attachment
      a.reload
      expect(a.grants_right?(student, :read)).to eql(true)
    end

    it "should allow students to download files" do
      a = attachment
      a.reload
      expect(a.grants_right?(student, :download)).to eql(true)
    end

    it "should allow students to read (but not download) locked files" do
      a = attachment
      a.update_attribute(:locked, true)
      a.reload
      expect(a.grants_right?(student, :read)).to eql(true)
      expect(a.grants_right?(student, :download)).to eql(false)
    end

    it "should allow user access based on 'file_access_user_id' and 'file_access_expiration' in the session" do
      a = attachment
      expect(a.grants_right?(nil, :read)).to eql(false)
      expect(a.grants_right?(nil, :download)).to eql(false)
      mock_session = {
        'file_access_user_id' => student.id,
        'file_access_expiration' => 1.hour.from_now.to_i,
        'permissions_key' => SecureRandom.uuid
      }.with_indifferent_access
      expect(a.grants_right?(nil, mock_session, :read)).to eql(true)
      expect(a.grants_right?(nil, mock_session, :download)).to eql(true)
    end

    it "should correctly deny user access based on 'file_access_user_id'" do
      a = attachment_model(context: user)
      other_user = user_model
      mock_session = {
        'file_access_user_id' => other_user.id,
        'file_access_expiration' => 1.hour.from_now.to_i,
        'permissions_key' => SecureRandom.uuid
      }.with_indifferent_access
      expect(a.grants_right?(nil, mock_session, :read)).to eql(false)
      expect(a.grants_right?(nil, mock_session, :download)).to eql(false)
    end

    it "should allow user access to anyone if the course is public to auth users (with 'file_access_user_id' and 'file_access_expiration' in the session)" do
      mock_session = {
        'file_access_user_id' => user.id,
        'file_access_expiration' => 1.hour.from_now.to_i,
        'permissions_key' => SecureRandom.uuid
      }.with_indifferent_access

      a = attachment_model(context: course)
      expect(a.grants_right?(nil, mock_session, :read)).to eql(false)
      expect(a.grants_right?(nil, mock_session, :download)).to eql(false)

      course.is_public_to_auth_users = true
      course.save!
      a.reload
      AdheresToPolicy::Cache.clear

      expect(a.grants_right?(nil, :read)).to eql(false)
      expect(a.grants_right?(nil, :download)).to eql(false)
      expect(a.grants_right?(nil, mock_session, :read)).to eql(true)
      expect(a.grants_right?(nil, mock_session, :download)).to eql(true)
    end

    it "should not allow user access based on incorrect 'file_access_user_id' in the session" do
      a = attachment
      expect(a.grants_right?(nil, :read)).to eql(false)
      expect(a.grants_right?(nil, :download)).to eql(false)
      expect(a.grants_right?(nil, {'file_access_user_id' => 0, 'file_access_expiration' => 1.hour.from_now.to_i}, :read)).to eql(false)
    end

    it "should not allow user access based on incorrect 'file_access_expiration' in the session" do
      a = attachment
      expect(a.grants_right?(nil, :read)).to eql(false)
      expect(a.grants_right?(nil, :download)).to eql(false)
      expect(a.grants_right?(nil, {'file_access_user_id' => student.id, 'file_access_expiration' => 1.minute.ago.to_i}, :read)).to eql(false)
    end

    it "should allow students to download a file on an assessment question if it's part of a quiz they can read" do
      @bank = @course.assessment_question_banks.create!(:title => "bank")
      @a1 = attachment_with_context(@course, :display_name => "a1")
      @a2 = attachment_with_context(@course, :display_name => "a2")

      data1 = {'name' => "Hi", 'question_text' => "hey look <img src='/courses/#{@course.id}/files/#{@a1.id}/download'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
      @aquestion1 = @bank.assessment_questions.create!(:question_data => data1)
      aq_att1 = @aquestion1.attachments.first
      data2 = {'name' => "Hi", 'question_text' => "hey look <img src='/courses/#{@course.id}/files/#{@a2.id}/download'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
      @aquestion2 = @bank.assessment_questions.create!(:question_data => data2)
      aq_att2 = @aquestion2.attachments.first

      quiz = @course.quizzes.create!
      AssessmentQuestion.find_or_create_quiz_questions([@aquestion1], quiz.id, nil)
      quiz.publish!
      expect(aq_att1.grants_right?(student, :download)).to eq true
      expect(aq_att2.grants_right?(student, :download)).to eq false
    end
  end

  context "duplicate handling" do
    before :once do
      course_model
      @a1 = attachment_with_context(@course, :display_name => "a1")
      @a2 = attachment_with_context(@course, :display_name => "a2")
      @a = attachment_with_context(@course)
    end

    it "should handle overwriting duplicates" do
      @a.display_name = 'a1'
      deleted = @a.handle_duplicates(:overwrite)
      expect(@a.file_state).to eq 'available'
      @a1.reload
      expect(@a1.file_state).to eq 'deleted'
      expect(@a1.replacement_attachment).to eql @a
      expect(deleted).to eq [ @a1 ]
    end

    it "should update replacement pointers to replaced files" do
      @a.update_attribute(:display_name, 'a1')
      @a.handle_duplicates(:overwrite)
      expect(@a1.reload.replacement_attachment).to eql @a
      again = attachment_with_context(@course, :display_name => 'a1')
      again.handle_duplicates(:overwrite)
      expect(@a1.reload.replacement_attachment).to eql again
    end

    it "should update replacement pointers to replaced-then-renamed files" do
      @a.update_attribute(:display_name, 'a1')
      @a.handle_duplicates(:overwrite)
      expect(@a1.reload.replacement_attachment).to eql @a
      @a.update_attribute(:display_name, 'renamed')
      again = attachment_with_context(@course, :display_name => 'renamed')
      again.handle_duplicates(:overwrite)
      expect(@a1.reload.replacement_attachment).to eql again
    end

    it "should handle renaming duplicates" do
      @a.display_name = 'a1'
      deleted = @a.handle_duplicates(:rename)
      expect(deleted).to be_empty
      expect(@a.file_state).to eq 'available'
      @a1.reload
      expect(@a1.file_state).to eq 'available'
      expect(@a.display_name).to eq 'a1-1'
    end

    it "should update ContentTags when overwriting" do
      mod = @course.context_modules.create!(:name => "some module")
      tag1 = mod.add_item(:id => @a1.id, :type => 'attachment')
      tag2 = mod.add_item(:id => @a2.id, :type => 'attachment')
      mod.save!

      @a1.reload
      expect(@a1.could_be_locked).to be_truthy

      @a.display_name = 'a1'
      @a.handle_duplicates(:overwrite)
      tag1.reload
      expect(tag1).to be_active
      expect(tag1.content_id).to eq @a.id

      @a.reload
      expect(@a.could_be_locked).to be_truthy

      @a2.destroy
      tag2.reload
      expect(tag2).to be_deleted
    end

    it "should find replacement file by id if name changes" do
      @a.display_name = 'a1'
      @a.handle_duplicates(:overwrite)
      @a.display_name = 'renamed!!'
      @a.save!
      expect(@course.attachments.find(@a1.id)).to eql @a
    end

    it "should find replacement file by name if id isn't present" do
      @a.display_name = 'a1'
      @a.handle_duplicates(:overwrite)
      @a1.update_attribute(:replacement_attachment_id, nil)
      expect(@course.attachments.find(@a1.id)).to eql @a
    end

    it "preserves hidden state" do
      @a1.update_attribute(:file_state, 'hidden')
      @a.update_attribute(:display_name, 'a1')
      @a.handle_duplicates(:overwrite)
      expect(@a.reload.file_state).to eq 'hidden'
    end

    it "preserves unpublished state" do
      @a1.update_attribute(:locked, true)
      @a.update_attribute(:display_name, 'a1')
      @a.handle_duplicates(:overwrite)
      expect(@a.reload.locked).to eq true
    end

    it "preserves lock dates" do
      @a1.unlock_at = Date.new(2016, 1, 1)
      @a1.lock_at = Date.new(2016, 4, 1)
      @a1.save!
      @a.update_attribute(:display_name, 'a1')
      @a.handle_duplicates(:overwrite)
      expect(@a.reload.unlock_at).to eq @a1.reload.unlock_at
      expect(@a.lock_at).to eq @a1.lock_at
    end

    it "preserves usage rights" do
      usage_rights = @course.usage_rights.create! use_justification: 'creative_commons', legal_copyright: '(C) 2014 XYZ Corp', license: 'cc_by_nd'
      @a1.usage_rights = usage_rights
      @a1.save!
      @a.update_attribute(:display_name, 'a1')
      @a.handle_duplicates(:overwrite)
      expect(@a.reload.usage_rights).to eq usage_rights
    end

    it "forces rename semantics in submissions folders" do
      user_model
      a1 = attachment_model context: @user, folder: @user.submissions_folder, filename: 'a1.txt'
      a2 = attachment_model context: @user, folder: @user.submissions_folder, filename: 'a2.txt'
      a2.display_name = 'a1.txt'
      deleted = a2.handle_duplicates(:overwrite)
      expect(deleted).to be_empty
      a2.reload
      expect(a2.display_name).not_to eq 'a1.txt'
      expect(a2.display_name).not_to eq 'a2.txt'
    end

    context "sharding" do
      specs_require_sharding

      it "forms proper queries when run from a different shard" do
        @shard1.activate do
          @a.display_name = 'a1'
          deleted = @a.handle_duplicates(:overwrite)
          expect(@a.file_state).to eq 'available'
          @a1.reload
          expect(@a1.file_state).to eq 'deleted'
          expect(@a1.replacement_attachment).to eql @a
          expect(deleted).to eq [ @a1 ]
        end
      end
    end
  end

  describe "make_unique_filename" do
    it "should find a unique name for files" do
      existing_files = %w(a.txt b.txt c.txt)
      expect(Attachment.make_unique_filename("d.txt", existing_files)).to eq "d.txt"
      expect(existing_files).not_to be_include(Attachment.make_unique_filename("b.txt", existing_files))

      existing_files = %w(/a/b/a.txt /a/b/b.txt /a/b/c.txt)
      expect(Attachment.make_unique_filename("/a/b/d.txt", existing_files)).to eq "/a/b/d.txt"
      new_name = Attachment.make_unique_filename("/a/b/b.txt", existing_files)
      expect(existing_files).not_to be_include(new_name)
      expect(new_name).to match(%r{^/a/b/b[^.]+\.txt})
    end

    it "deals with missing extensions" do
      expect(Attachment.make_unique_filename('blah', ['blah'])).to eq 'blah-1'
    end

    it "puts the uniquifier before double extensions" do
      expect(Attachment.make_unique_filename('blah.tar.bz2', ['blah.tar.bz2'])).to eq 'blah-1.tar.bz2'
    end

    it "does not treat numbers after a decimal point as extensions" do
      expect(Attachment.make_unique_filename('section 11.5.doc', ['section 11.5.doc'])).to eq 'section 11.5-1.doc'
      expect(Attachment.make_unique_filename('3.3.2018 footage.mp4', ['3.3.2018 footage.mp4'])).to eq '3.3.2018 footage-1.mp4'
    end
  end

  context "download/inline urls" do
    before :once do
      course_model
    end

    it "should work with s3 storage" do
      s3_storage!
      attachment = attachment_with_context(@course, :display_name => 'foo')
      expect(attachment.public_download_url).to match(/response-content-disposition=attachment/)
      expect(attachment.public_inline_url).to match(/response-content-disposition=inline/)
    end

    it 'should allow custom ttl for download_url' do
      attachment = attachment_with_context(@course, :display_name => 'foo')
      allow(attachment).to receive(:public_url) # allow other calls due to, e.g., save
      expect(attachment).to receive(:public_url).with(include(:expires_in => 3600.seconds))
      attachment.public_download_url
      expect(attachment).to receive(:public_url).with(include(:expires_in => 2.days))
      attachment.public_download_url(2.days)
    end

    it 'should allow custom ttl for root_account' do
      attachment = attachment_with_context(@course, :display_name => 'foo')
      root = @course.root_account
      root.settings[:s3_url_ttl_seconds] = 3.days.seconds.to_s
      root.save!
      expect(attachment).to receive(:public_url).with(include(expires_in: 3.days.to_i.seconds))
      attachment.public_download_url
    end

    it "should include response-content-disposition" do
      attachment = attachment_with_context(@course, :display_name => 'foo')
      allow(attachment).to receive(:authenticated_s3_url) # allow other calls due to, e.g., save
      expect(attachment).to receive(:authenticated_s3_url).with(include(:response_content_disposition => %(attachment; filename="foo"; filename*=UTF-8''foo)))
      attachment.public_download_url
      expect(attachment).to receive(:authenticated_s3_url).with(include(:response_content_disposition => %(inline; filename="foo"; filename*=UTF-8''foo)))
      attachment.public_inline_url
    end

    it "should use the display_name, not filename, in the response-content-disposition" do
      attachment = attachment_with_context(@course, :filename => 'bar', :display_name => 'foo')
      allow(attachment).to receive(:authenticated_s3_url) # allow other calls due to, e.g., save
      expect(attachment).to receive(:authenticated_s3_url).with(include(:response_content_disposition => %(attachment; filename="foo"; filename*=UTF-8''foo)))
      attachment.public_download_url
    end

    it "should http quote the filename in the response-content-disposition if necessary" do
      attachment = attachment_with_context(@course, :display_name => 'fo"o')
      allow(attachment).to receive(:authenticated_s3_url) # allow other calls due to, e.g., save
      expect(attachment).to receive(:authenticated_s3_url).with(include(:response_content_disposition => %(attachment; filename="fo\\"o"; filename*=UTF-8''fo%22o)))
      attachment.public_download_url
    end

    it "should sanitize filename with iconv" do
      a = attachment_with_context(@course, :display_name => "糟糕.pdf")
      sanitized_filename = Iconv.conv("ASCII//TRANSLIT//IGNORE", "UTF-8", a.display_name)
      allow(a).to receive(:authenticated_s3_url)
      expect(a).to receive(:authenticated_s3_url).with(include(:response_content_disposition => %(attachment; filename="#{sanitized_filename}"; filename*=UTF-8''%E7%B3%9F%E7%B3%95.pdf)))
      a.public_download_url
    end

    it "should escape all non-alphanumeric characters in the utf-8 filename" do
      attachment = attachment_with_context(@course, :display_name => '"This file[0] \'{has}\' \# awesome `^<> chars 100%,|<-pipe"')
      allow(attachment).to receive(:authenticated_s3_url)
      expect(attachment).to receive(:authenticated_s3_url).with(include(:response_content_disposition => %(attachment; filename="\\\"This file[0] '{has}' \\# awesome `^<> chars 100%,|<-pipe\\\""; filename*=UTF-8''%22This%20file%5B0%5D%20%27%7Bhas%7D%27%20%5C%23%20awesome%20%60%5E%3C%3E%20chars%20100%25%2C%7C%3C%2Dpipe%22)))
      attachment.public_download_url
    end
  end

  context "root_account_id" do
    before :once do
      account_model
      course_model(:account => @account)
      @a = attachment_with_context(@course)
    end

    it "should return account id for normal namespaces" do
      @a.namespace = "account_#{@account.id}"
      expect(@a.root_account_id).to eq @account.id
    end

    it "should return account id for localstorage namespaces" do
      @a.namespace = "_localstorage_/#{@account.file_namespace}"
      expect(@a.root_account_id).to eq @account.id
    end

    it "should immediately infer the namespace if not yet set" do
      Attachment.current_root_account = nil
      @a = Attachment.new(:context => @course)
      expect(@a).to be_new_record
      expect(@a.read_attribute(:namespace)).to be_nil
      expect(@a.namespace).not_to be_nil
      expect(@a.read_attribute(:namespace)).not_to be_nil
      expect(@a.root_account_id).to eq @account.id
    end

    it "should not infer the namespace if it's not a new record" do
      Attachment.current_root_account = nil
      attachment_model(:context => submission_model)
      expect(@attachment).not_to be_new_record
      expect(@attachment.read_attribute(:namespace)).to be_nil
      expect(@attachment.namespace).to be_nil
      expect(@attachment.read_attribute(:namespace)).to be_nil
    end

    context "sharding" do
      specs_require_sharding

      it "stores a local id on the birth shard" do
        Attachment.current_root_account = Account.default
        att = Attachment.new
        att.infer_namespace
        expect(att.namespace).to eq Account.default.asset_string
        expect(att.root_account_id).to eq Account.default.local_id
        @shard1.activate do
          expect(att.root_account_id).to eq Account.default.global_id
        end
      end

      it "stores a global id on all other shards" do
        a = nil
        att = nil
        @shard1.activate do
          a = Account.create!
          Attachment.current_root_account = a
          att = Attachment.new
          att.infer_namespace
          expect(att.namespace).to eq a.global_asset_string
          expect(att.root_account_id).to eq a.local_id
        end
        expect(att.root_account_id).to eq a.global_id
      end

      it "interprets root_account_id correctly, even when local on not the birth shard" do
        a = nil
        att = nil
        @shard1.activate do
          a = Account.create!
          att = Attachment.new
          att.namespace = a.asset_string
          expect(att.root_account_id).to eq a.local_id
        end
        expect(att.root_account_id).to eq a.global_id
      end

      it "stores ID for a cross-shard attachment" do
        Attachment.current_root_account = Account.default
        att = nil
        @shard1.activate do
          att = Attachment.new
          att.infer_namespace
          expect(att.namespace).to eq Account.default.global_asset_string
          expect(att.root_account_id).to eq Account.default.global_id
        end
        expect(att.root_account_id).to eq Account.default.local_id
      end
    end
  end

  context "encoding detection" do
    it "should include the charset when appropriate" do
      a = Attachment.new
      a.content_type = 'text/html'
      expect(a.content_type_with_encoding).to eq 'text/html'
      a.encoding = ''
      expect(a.content_type_with_encoding).to eq 'text/html'
      a.encoding = 'UTF-8'
      expect(a.content_type_with_encoding).to eq 'text/html; charset=UTF-8'
      a.encoding = 'mycustomencoding'
      expect(a.content_type_with_encoding).to eq 'text/html; charset=mycustomencoding'
    end

    it "should schedule encoding detection when appropriate" do
      expects_job_with_tag('Attachment#infer_encoding', 0) do
        attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'image/png'), :content_type => 'image/png')
      end
      expects_job_with_tag('Attachment#infer_encoding', 1) do
        attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')
      end
      expects_job_with_tag('Attachment#infer_encoding', 0) do
        attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html', :encoding => 'UTF-8')
      end
    end

    it "should properly infer encoding" do
      attachment_model(:uploaded_data => stub_png_data('blank.gif', "GIF89a\001\000\001\000\200\377\000\377\377\377\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"))
      expect(@attachment.encoding).to be_nil
      @attachment.infer_encoding
      # can't figure out GIF encoding
      expect(@attachment.encoding).to eq ''

      attachment_model(:uploaded_data => stub_png_data('blank.txt', "Hello World!"))
      expect(@attachment.encoding).to be_nil
      @attachment.infer_encoding
      expect(@attachment.encoding).to eq 'UTF-8'

      attachment_model(:uploaded_data => stub_png_data('blank.txt', "\xc2\xa9 2011"))
      expect(@attachment.encoding).to be_nil
      @attachment.infer_encoding
      expect(@attachment.encoding).to eq 'UTF-8'

      attachment_model(:uploaded_data => stub_png_data('blank.txt', "can't read me"))
      allow(@attachment).to receive(:open).and_raise(IOError)
      @attachment.infer_encoding
      expect(@attachment.encoding).to eq nil
    end
  end

  context "sharding" do
    specs_require_sharding

    it "grants rights to owning user even if the user is on a seperate shard" do
      user = nil
      attachments = []

      @shard1.activate do
        user = User.create!
        expect(user.attachments.build.grants_right?(user, :read)).to be_truthy
      end

      @shard2.activate do
        expect(user.attachments.build.grants_right?(user, :read)).to be_truthy
      end

      expect(user.attachments.build.grants_right?(user, :read)).to be_truthy
    end
  end

  context "#change_namespace and #make_childless" do
    before :once do
      @old_account = account_model
      @new_account = account_model
    end

    before :each do
      s3_storage!
      Attachment.current_root_account = @old_account
      @root = attachment_model(filename: 'unknown 2.loser')
      @child = attachment_model(:root_attachment => @root)

      @old_object = double('old object')
      @new_object = double('new object')
      new_full_filename = @root.full_filename.sub(@root.namespace, @new_account.file_namespace)
      allow(@root.bucket).to receive(:object).with(@root.full_filename).and_return(@old_object)
      allow(@root.bucket).to receive(:object).with(new_full_filename).and_return(@new_object)
    end

    it "should fail for non-root attachments" do
      expect(@old_object).to receive(:copy_to).never
      expect { @child.change_namespace(@new_account.file_namespace) }.to raise_error('change_namespace must be called on a root attachment')
      expect(@root.reload.namespace).to eq @old_account.file_namespace
      expect(@child.reload.namespace).to eq @root.reload.namespace
    end

    it "should not copy if the destination exists" do
      expect(@new_object).to receive(:exists?).and_return(true)
      expect(@old_object).to receive(:copy_to).never
      @root.change_namespace(@new_account.file_namespace)
      expect(@root.namespace).to eq @new_account.file_namespace
      expect(@child.reload.namespace).to eq @root.namespace
    end

    it "should rename root attachments and update children" do
      expect(@new_object).to receive(:exists?).and_return(false)
      expect(@old_object).to receive(:copy_to).with(@new_object, anything)
      @root.change_namespace(@new_account.file_namespace)
      expect(@root.namespace).to eq @new_account.file_namespace
      expect(@child.reload.namespace).to eq @root.namespace
    end

    it 'should allow making a root_attachment childless' do
      @child.update_attribute(:filename, 'invalid')
      expect(@root.s3object).to receive(:exists?).and_return(true)
      expect(@child).to receive(:s3object).and_return(@old_object)
      expect(@old_object).to receive(:exists?).and_return(true)
      @root.make_childless(@child)
      expect(@root.reload.children).to eq []
      expect(@child.reload.root_attachment_id).to eq nil
      expect(@child.read_attribute(:filename)).to eq @root.filename
    end
  end

  context "s3 storage with sharding" do

    let(:sz) { "640x>" }
    specs_require_sharding

    before :each do
      s3_storage!
      attachment_model(:uploaded_data => stub_png_data, :filename => 'profile.png')
    end

    it "should have namespaced thumb" do

      @shard1.activate do

        @attachment.thumbnail || @attachment.build_thumbnail.save!
        thumb = @attachment.thumbnail

        # i can't seem to get a s3 url so I am just going to make sure the thumbnail namespace was inherited from the attachment
        expect(thumb.namespace).to eq @attachment.namespace
        expect(thumb.authenticated_s3_url).to be_include @attachment.namespace
      end
    end

    it "shouldn't have namespaced thumb when namespace is nil" do

      @shard1.activate do

        @attachment.thumbnail || @attachment.build_thumbnail.save!
        thumb = @attachment.thumbnail

        # nil out namespace so we can make sure the url generating is working properly
        thumb.namespace = nil
        expect(thumb.authenticated_s3_url).not_to be_include @attachment.namespace
      end
    end
  end

  context "has_thumbnail?" do
    context "non-instfs attachment" do
      it "should be false when it doesn't have a thumbnail object (yet?)" do
        attachment_model(uploaded_data: stub_png_data)
        if @attachment.thumbnail
          @attachment.thumbnail.destroy!
          @attachment.thumbnail = nil
        end
        expect(@attachment.has_thumbnail?).to be false
      end

      it "should be false when it doesn't have a thumbnail object even if instfs is enabled" do
        attachment_model(uploaded_data: stub_png_data)
        if @attachment.thumbnail
          @attachment.thumbnail.destroy!
          @attachment.thumbnail = nil
        end
        allow(InstFS).to receive(:enabled?).and_return true
        expect(@attachment.has_thumbnail?).to be false
      end

      it "should be true when it has a thumbnail object" do
        attachment_model(uploaded_data: stub_png_data)
        @attachment.thumbnail || @attachment.build_thumbnail.save!
        expect(@attachment.has_thumbnail?).to be true
      end
    end

    context "instfs attachment" do
      before do
        allow(InstFS).to receive(:enabled?).and_return true
        allow(InstFS).to receive(:jwt_secret).and_return 'secret'
        allow(InstFS).to receive(:app_host).and_return 'instfs'
      end

      it "should be false when not thumbnailable" do
        attachment_model(instfs_uuid: 'abc', content_type: 'text/plain')
        expect(@attachment.has_thumbnail?).to be false
      end

      it "should be true when thumbnailable" do
        attachment_model(instfs_uuid: 'abc', content_type: 'image/png')
        expect(@attachment.has_thumbnail?).to be true
      end

      it "should be true when thumbnailable and instfs is later disabled" do
        attachment_model(instfs_uuid: 'abc', content_type: 'image/png')
        allow(InstFS).to receive(:enabled?).and_return false
        expect(@attachment.has_thumbnail?).to be true
      end
    end
  end

  context "thumbnail_url (non-instfs)" do
    it "should be the thumbnail's url" do
      attachment_model(uploaded_data: stub_png_data)
      @attachment.thumbnail || @attachment.build_thumbnail.save!
      expect(@attachment.thumbnail_url).to eq @attachment.thumbnail.cached_s3_url
    end
  end

  context "dynamic thumbnails" do
    let(:sz) { "640x>" }

    before do
      attachment_model(:uploaded_data => stub_png_data)
    end

    around do |example|
      Timecop.freeze(Time.now.utc, &example)
    end

    it "should use the default size if an unknown size is passed in" do
      @attachment.thumbnail || @attachment.build_thumbnail.save!
      url = @attachment.thumbnail_url(:size => "100x100")
      expect(url).to be_present
      expect(url).to eq @attachment.thumbnail.authenticated_s3_url(expires_in: 144.hours)
    end

    it "should generate the thumbnail on the fly" do
      thumb = @attachment.thumbnails.where(thumbnail: "640x>").first
      expect(thumb).to eq nil

      expect(@attachment).to receive(:create_or_update_thumbnail).with(anything, sz, sz) {
        @attachment.thumbnails.create!(:thumbnail => "640x>", :uploaded_data => stub_png_data)
      }
      url = @attachment.thumbnail_url(:size => "640x>")
      expect(url).to be_present
      thumb = @attachment.thumbnails.where(thumbnail: "640x>").first
      expect(thumb).to be_present
      expect(url).to eq thumb.authenticated_s3_url(expires_in: 144.hours)
    end

    it "should use the existing thumbnail if present" do
      expect(@attachment).to receive(:create_or_update_thumbnail).with(anything, sz, sz) {
        @attachment.thumbnails.create!(:thumbnail => "640x>", :uploaded_data => stub_png_data)
      }
      url = @attachment.thumbnail_url(:size => "640x>")
      expect(@attachment).to receive(:create_dynamic_thumbnail).never
      url = @attachment.thumbnail_url(:size => "640x>")
      thumb = @attachment.thumbnails.where(thumbnail: "640x>").first
      expect(url).to be_present
      expect(thumb).to be_present
      expect(url).to eq thumb.authenticated_s3_url(expires_in: 144.hours)
    end
  end

  describe '.allows_thumbnails_for_size' do
    it 'inevitably returns false if there is no size provided' do
      expect(Attachment.allows_thumbnails_of_size?(nil)).to be_falsey
    end

    it 'returns true if the provided size is in the configured dynamic sizes' do
      expect(Attachment.allows_thumbnails_of_size?(Attachment::DYNAMIC_THUMBNAIL_SIZES.first)).to be_truthy
    end

    it 'returns false if the provided size is not in the configured dynamic sizes' do
      expect(Attachment.allows_thumbnails_of_size?('nonsense')).to be_falsey
    end
  end

  describe "thumbnail source image size limitation" do
    before do
      local_storage! # s3 attachment data is stubbed out, so there is no image to identify the size of
      course_factory
    end

    it 'creates thumbnails for smaller images' do
      att = @course.attachments.create! :uploaded_data => jpeg_data_frd, :filename => 'ok.jpg'
      expect(att.thumbnail).not_to be_nil
      expect(att.thumbnail.width).not_to be_nil
    end

    it 'does not create thumbnails for larger images' do
      att = @course.attachments.create! :uploaded_data => one_hundred_megapixels_of_highly_compressed_png_data, :filename => '3vil.png'
      expect(att.thumbnail).to be_nil
    end
  end

  context "notifications" do
    before :once do
      course_model(:workflow_state => "available")
      # ^ enrolls @teacher in @course

      # create a student to receive notifications
      @student = user_model
      @student.register!
      e = @course.enroll_student(@student).accept
      @cc = @student.communication_channels.create(:path => "default@example.com")
      @cc.confirm!

      @student_ended = user_model
      @student_ended.register!
      @section_ended = @course.course_sections.create!(end_at: Time.zone.now - 1.day)
      @course.enroll_student(@student_ended, :section => @section_ended).accept
      @cc_ended = @student_ended.communication_channels.create(:path => "default2@example.com")
      @cc_ended.confirm!

      NotificationPolicy.create(:notification => Notification.create!(:name => 'New File Added'), :communication_channel => @cc, :frequency => "immediately")
      NotificationPolicy.create(:notification => Notification.create!(:name => 'New Files Added'), :communication_channel => @cc, :frequency => "immediately")

      NotificationPolicy.create(:notification => Notification.create!(:name => 'New File Added - ended'),
                                :communication_channel => @cc_ended, :frequency => "immediately")
      NotificationPolicy.create(:notification => Notification.create!(:name => 'New Files Added - ended'),
                                :communication_channel => @cc_ended, :frequency => "immediately")
    end

    it "should send a single-file notification" do
      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')
      expect(@attachment.need_notify).to be_truthy

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).not_to be_truthy
      expect(Message.where(user_id: @student, notification_name: 'New File Added').first).not_to be_nil
    end

    it "should send a batch notification" do
      att1 = attachment_model(:uploaded_data => stub_file_data('file1.txt', nil, 'text/html'), :content_type => 'text/html')
      att2 = attachment_model(:uploaded_data => stub_file_data('file2.txt', nil, 'text/html'), :content_type => 'text/html')
      att3 = attachment_model(:uploaded_data => stub_file_data('file3.txt', nil, 'text/html'), :content_type => 'text/html')
      [att1, att2, att3].each {|att| expect(att.need_notify).to be_truthy}

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      [att1, att2, att3].each {|att| expect(att.reload.need_notify).not_to be_truthy}
      expect(Message.where(user_id: @student, notification_name: 'New Files Added').first).not_to be_nil
    end

    it "should not notify before a file finishes uploading" do
      # it's weird, but file_state is 'deleted' until the upload completes, when it is changed to 'available'
      attachment_model(:file_state => 'deleted', :content_type => 'text/html')
      expect(@attachment.need_notify).not_to be_truthy
    end

    it "should postpone notification of a batch judged to be in-progress" do
      att1 = attachment_model(:uploaded_data => stub_file_data('file1.txt', nil, 'text/html'), :content_type => 'text/html')
      att2 = attachment_model(:uploaded_data => stub_file_data('file2.txt', nil, 'text/html'), :content_type => 'text/html')
      att3 = attachment_model(:uploaded_data => stub_file_data('file3.txt', nil, 'text/html'), :content_type => 'text/html')
      [att1, att2, att3].each {|att| expect(att.need_notify).to be_truthy}

      Timecop.freeze(2.minutes.from_now) { Attachment.do_notifications }
      [att1, att2, att3].each {|att| expect(att.reload.need_notify).to be_truthy}
      expect(Message.where(user_id: @student, notification_name: 'New File Added').first).to be_nil

      Timecop.freeze(6.minutes.from_now) { Attachment.do_notifications }
      [att1, att2, att3].each {|att| expect(att.reload.need_notify).not_to be_truthy}
      expect(Message.where(user_id: @student, notification_name: 'New Files Added').first).not_to be_nil
    end

    it "should discard really old pending notifications" do
      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')
      expect(@attachment.need_notify).to be_truthy

      Timecop.freeze(1.week.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).to be_falsey
      expect(Message.where(user_id: @student, notification_name: 'New File Added').first).to be_nil
      expect(Message.where(user_id: @student, notification_name: 'New File Added').first).to be_nil
    end

    it "should respect save_without_broadcasting" do
      att1 = attachment_model(:file_state => 'deleted', :uploaded_data => stub_file_data('file1.txt', nil, 'text/html'), :content_type => 'text/html')
      att2 = attachment_model(:file_state => 'deleted', :uploaded_data => stub_file_data('file2.txt', nil, 'text/html'), :content_type => 'text/html')
      att3 = attachment_model(:file_state => 'deleted', :uploaded_data => stub_file_data('file2.txt', nil, 'text/html'), :content_type => 'text/html')

      expect(att1.need_notify).not_to be_truthy
      att1.file_state = 'available'
      att1.save!
      expect(att1.need_notify).to be_truthy

      expect(att2.need_notify).not_to be_truthy
      att2.file_state = 'available'
      att2.save_without_broadcasting
      expect(att2.need_notify).not_to be_truthy

      expect(att3.need_notify).not_to be_truthy
      att3.file_state = 'available'
      att3.save_without_broadcasting!
      expect(att3.need_notify).not_to be_truthy
    end

    it "should not send notifications to students if the file is uploaded to a locked folder" do
      @teacher.register!
      cc = @teacher.communication_channels.create!(:path => "default@example.com")
      cc.confirm!
      NotificationPolicy.create!(:notification => Notification.where(name: 'New File Added').first, :communication_channel => cc, :frequency => "immediately")

      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')

      @attachment.folder.locked = true
      @attachment.folder.save!

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).not_to be_truthy
      expect(Message.where(user_id: @student, notification_name: 'New File Added').first).to be_nil
      expect(Message.where(user_id: @teacher, notification_name: 'New File Added').first).not_to be_nil
    end

    it "should not send notifications to students if the file is unpublished because of usage rights" do
      @teacher.register!
      cc = @teacher.communication_channels.create!(:path => "default@example.com")
      cc.confirm!
      NotificationPolicy.create!(:notification => Notification.where(name: 'New File Added').first, :communication_channel => cc, :frequency => "immediately")

      @course.enable_feature! :usage_rights_required
      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')
      @attachment.set_publish_state_for_usage_rights
      @attachment.save!

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).not_to be_truthy
      expect(Message.where(user_id: @student, notification_name: 'New File Added').first).to be_nil
      expect(Message.where(user_id: @teacher, notification_name: 'New File Added').first).not_to be_nil
    end

    it "should not send notifications to students if the files navigation is hidden from student view" do
      @teacher.register!
      cc = @teacher.communication_channels.create!(:path => "default@example.com")
      cc.confirm!
      NotificationPolicy.create!(:notification => Notification.where(name: 'New File Added').first, :communication_channel => cc, :frequency => "immediately")

      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')

      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).not_to be_truthy
      expect(Message.where(user_id: @student, notification_name: 'New File Added').first).to be_nil
      expect(Message.where(user_id: @teacher, notification_name: 'New File Added').first).not_to be_nil
    end

    it "should not fail if the attachment context does not have participants" do
      cm = ContentMigration.create!(:context => course_factory)
      attachment_model(:context => cm, :uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')

      Attachment.where(:id => @attachment).update_all(:need_notify => true)

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }
    end

    it "doesn't send notifications for a concluded course" do
      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')
      @course.soft_conclude!
      @course.save!
      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }
      expect(Message.where(user_id: @student, notification_name: 'New File Added').first).to be_nil
    end

    it "doesn't send notifications for a concluded section in an active course" do
      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')
      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }
      expect(Message.where(user_id: @student_ended, notification_name: 'New File Added').first).to be_nil
    end
  end

  context "quota" do
    it "should give small files a minimum quota size" do
      course_model
      attachment_model(:context => @course, :uploaded_data => stub_png_data, :size => 25)
      quota = Attachment.get_quota(@course)
      expect(quota[:quota_used]).to eq Attachment.minimum_size_for_quota
    end

    it "should not count attachments a student has used for submissions towards the quota" do
      course_with_student(:active_all => true)
      attachment_model(:context => @user, :uploaded_data => stub_png_data, :filename => "homework.png")
      @attachment.update_attribute(:size, 1.megabyte)

      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 1.megabyte

      @assignment = @course.assignments.create!
      sub = @assignment.submit_homework(@user, attachments: [@attachment])

      attachment_model(:context => @user, :uploaded_data => stub_png_data, :filename => "otherfile.png")
      @attachment.update_attribute(:size, 1.megabyte)

      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 1.megabyte
    end

    it "should not count attachments a student has used for graded discussion replies towards the quota" do
      course_with_student(:active_all => true)
      attachment_model(:context => @user, :uploaded_data => stub_png_data, :filename => "homework.png")
      @attachment.update_attribute(:size, 1.megabyte)

      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 1.megabyte

      assignment = @course.assignments.create!(:title => "asmt")
      topic = @course.discussion_topics.create!(:title => 'topic', :assignment => assignment)
      entry = topic.reply_from(:user => @student, :text => "entry")
      entry.attachment = @attachment
      entry.save!

      attachment_model(:context => @user, :uploaded_data => stub_png_data, :filename => "otherfile.png")
      @attachment.update_attribute(:size, 1.megabyte)

      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 1.megabyte
    end

    it "should not count attachments in submissions folders toward the quota" do
      user_model
      attachment_model(:context => @user, :uploaded_data => stub_png_data, :filename => 'whatever.png', :folder => @user.submissions_folder)
      @attachment.update_attribute(:size, 1.megabyte)
      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 0
    end

    it "should not count attachments in group submissions folders toward the quota" do
      group_model
      attachment_model(:context => @group, :uploaded_data => stub_png_data, :filename => 'whatever.png', :folder => @group.submissions_folder)
      @attachment.update_attribute(:size, 1.megabyte)
      quota = Attachment.get_quota(@group)
      expect(quota[:quota_used]).to eq 0
    end
  end

  context "#open" do
    include WebMock::API

    context "instfs branch" do
      before do
        user_model
        attachment_model(:context => @user)
        public_url = 'http://www.example.com/foo'
        allow(@attachment).to receive(:instfs_hosted?).and_return true
        allow(@attachment).to receive(:public_url).and_return public_url

        stub_request(:get, public_url).
          to_return(status: 200, body: "test response body", headers: {})
      end

      it "should stream data to the block given" do
        callback = false
        @attachment.open do |data|
          expect(data).to eq "test response body"
          callback = true
        end
        expect(callback).to eq true
      end

      it "should stream to a tempfile without a block given" do
        file = @attachment.open
        expect(file).to be_a(Tempfile)
        expect(file.read).to eq("test response body")
      end
    end

    context "s3_storage" do
      before do
        s3_storage!
        attachment_model
      end

      it "should stream data to the block given" do
        callback = false
        data = ["test", false]
        tempfile = double
        expect(tempfile).to receive(:binmode)
        expect(tempfile).to receive(:rewind)
        expect(tempfile).to receive(:path)

        expect(Tempfile).to receive(:new).and_return(tempfile)
        actual_file = double()
        expect(actual_file).to receive(:read).twice { data.shift }
        expect(File).to receive(:open).and_yield(actual_file)
        expect_any_instance_of(@attachment.s3object.class).to receive(:get).with(include(:response_target))
        @attachment.open { |data| expect(data).to eq "test"; callback = true }
        expect(callback).to eq true
      end

      it "should stream to a tempfile without a block given" do
        expect_any_instance_of(@attachment.s3object.class).to receive(:get).with(include(:response_target))
        file = @attachment.open
        expect(file).to be_a(Tempfile)
      end
    end
  end

  context "#process_s3_details!" do
    before :once do
      attachment_model(filename: 'new filename')
    end

    before :each do
      allow(Attachment).to receive(:local_storage?).and_return(false)
      allow(Attachment).to receive(:s3_storage?).and_return(true)
      allow(@attachment).to receive(:s3object).and_return(double('s3object'))
      allow(@attachment).to receive(:after_attachment_saved)
    end

    context "deduplication" do
      before :once do
        attachment = @attachment
        @existing_attachment = attachment_model(filename: 'existing filename')
        @child_attachment = attachment_model(root_attachment: @existing_attachment)
        @attachment = attachment
      end

      before :each do
        allow(@existing_attachment).to receive(:s3object).and_return(double('existing_s3object'))
        allow(@attachment).to receive(:find_existing_attachment_for_md5).and_return(@existing_attachment)
      end

      context "existing attachment has s3object" do
        before do
          allow(@existing_attachment.s3object).to receive(:exists?).and_return(true)
          allow(@attachment.s3object).to receive(:delete)
        end

        it "should delete the new (redundant) s3object" do
          expect(@attachment.s3object).to receive(:delete).once
          @attachment.process_s3_details!({})
        end

        it "should put the new attachment under the existing attachment" do
          @attachment.process_s3_details!({})
          expect(@attachment.reload.root_attachment).to eq @existing_attachment
        end

        it "should retire the new attachment's filename" do
          @attachment.process_s3_details!({})
          expect(@attachment.reload.filename).to eq @existing_attachment.filename
        end
      end

      context "existing attachment is missing s3object" do
        before do
          allow(@existing_attachment.s3object).to receive(:exists?).and_return(false)
        end

        it "should not delete the new s3object" do
          expect(@attachment.s3object).to receive(:delete).never
          @attachment.process_s3_details!({})
        end

        it "should not put the new attachment under the existing attachment" do
          @attachment.process_s3_details!({})
          expect(@attachment.reload.root_attachment).to be_nil
        end

        it "should not retire the new attachment's filename" do
          @attachment.process_s3_details!({})
          @attachment.reload.filename == 'new filename'
        end

        it "should put the existing attachment under the new attachment" do
          @attachment.process_s3_details!({})
          expect(@existing_attachment.reload.root_attachment).to eq @attachment
        end

        it "should retire the existing attachment's filename" do
          @attachment.process_s3_details!({})
          expect(@existing_attachment.reload.read_attribute(:filename)).to be_nil
          expect(@existing_attachment.filename).to eq @attachment.filename
        end

        it "should reparent the child attachment under the new attachment" do
          @attachment.process_s3_details!({})
          expect(@child_attachment.reload.root_attachment).to eq @attachment
        end
      end
    end
  end

  context 'permissions' do
    describe ':attach_to_submission_comment' do
      it 'works for assignments if you own the attachment' do
        @s1, @s2 = n_students_in_course(2)
        @assignment = @course.assignments.create! name: 'blah'
        @attachment = Attachment.create! context: @assignment,
          filename: "foo.txt",
          uploaded_data: StringIO.new("bar"),
          user: @s1
        expect(@attachment.grants_right?(@s1, :attach_to_submission_comment)).to be_truthy
        expect(@attachment.grants_right?(@s2, :attach_to_submission_comment)).to be_falsey
      end
    end
  end

  describe "#full_path" do
    it "shouldn't puke for things that don't have folders" do
      attachment_obj_with_context(Account.default.default_enrollment_term)
      @attachment.folder = nil
      expect(@attachment.full_path).to eq "/#{@attachment.display_name}"
    end
  end

  describe ".clone_url_strand" do
    it "falls back for invalid URLs" do
      expect(Attachment.clone_url_strand("")).to eq "file_download"
    end

    it "gives the host for 'local' host" do
      expect(Attachment.clone_url_strand("http://localhost:9090/image.jpg")).to eq ["file_download", "localhost"]
    end

    it "gives the full host for simple domain" do
      expect(Attachment.clone_url_strand("http://google.com/image.jpg")).to eq ["file_download", "google.com"]
    end

    it "strips subdomains" do
      expect(Attachment.clone_url_strand("http://cdn.google.com/image.jpg")).to eq ["file_download", "google.com"]
    end

    it "accepts overrides" do
      allow(Attachment).to receive(:clone_url_strand_overrides).and_return("cdn.google.com" => "cdn")
      expect(Attachment.clone_url_strand("http://cdn.google.com/image.jpg")).to eq ["file_download", "cdn"]
    end
  end

  describe ".clone_url_as_attachment" do
    it "should reject invalid urls" do
      expect { Attachment.clone_url_as_attachment("ftp://some/stuff") }.to raise_error(ArgumentError)
    end

    it "should not raise on non-200 responses" do
      url = "http://example.com/test.png"
      expect(CanvasHttp).to receive(:get).with(url).and_yield(double('code' => '401'))
      expect { Attachment.clone_url_as_attachment(url) }.to raise_error(CanvasHttp::InvalidResponseCodeError)
    end

    it "should use an existing attachment if passed in" do
      url = "http://example.com/test.png"
      a = attachment_model
      expect(CanvasHttp).to receive(:get).with(url).and_yield(FakeHttpResponse.new('200', 'this is a jpeg', 'content-type' => 'image/jpeg'))
      Attachment.clone_url_as_attachment(url, :attachment => a)
      a.save!
      expect(a.open.read).to eq "this is a jpeg"
    end

    it "should not overwrite the content_type if already present" do
      url = "http://example.com/test.png"
      a = attachment_model(:content_type => 'image/jpeg')
      expect(CanvasHttp).to receive(:get).with(url).and_yield(FakeHttpResponse.new('200', 'this is a jpeg', 'content-type' => 'application/octet-stream'))
      Attachment.clone_url_as_attachment(url, :attachment => a)
      a.save!
      expect(a.open.read).to eq "this is a jpeg"
      expect(a.content_type).to eq 'image/jpeg'
    end

    it "should detect the content_type from the body" do
      url = "http://example.com/test.png"
      expect(CanvasHttp).to receive(:get).with(url).and_yield(FakeHttpResponse.new('200', 'this is a jpeg', 'content-type' => 'image/jpeg'))
      att = Attachment.clone_url_as_attachment(url)
      expect(att).to be_present
      expect(att).to be_new_record
      expect(att.content_type).to eq 'image/jpeg'
      att.context = Account.default
      att.save!
      expect(att.open.read).to eq 'this is a jpeg'
    end
  end

  describe "infer_namespace" do
    it "should infer the correct namespace from the root attachment" do
      local_storage!
      allow(Rails.env).to receive(:development?).and_return(true)
      course_factory
      a1 = attachment_model(context: @course, uploaded_data: default_uploaded_data)
      a2 = attachment_model(context: @course, uploaded_data: default_uploaded_data)
      expect(a2.root_attachment).to eql(a1)
      expect(a2.namespace).to eql(a1.namespace)
    end
  end

  it "should be able to add a hidden attachment as a context module item" do
    course_factory
    att = attachment_model(context: @course, uploaded_data: default_uploaded_data)
    att.hidden = true
    att.save!
    mod = @course.context_modules.create!(:name => "some module")
    tag1 = mod.add_item(:id => att.id, :type => 'attachment')
    expect(tag1).not_to be_nil
  end

  it "should unlock files at the right time even if they're accessed shortly before" do
    enable_cache do
      course_with_student :active_all => true
      attachment_model uploaded_data: default_uploaded_data, unlock_at: 30.seconds.from_now
      expect(@attachment.grants_right?(@student, :download)).to eq false # prime cache
      Timecop.freeze(@attachment.unlock_at + 1.second) do
        run_jobs
        expect(Attachment.find(@attachment.id).grants_right?(@student, :download)).to eq true
      end
    end
  end

  it "should not be locked_for soft-concluded admin users" do
    term = Account.default.enrollment_terms.create!
    term.set_overrides(Account.default, 'TeacherEnrollment' => {:end_at => 3.days.ago})
    course_with_teacher(:active_all => true)
    @course.enrollment_term = term
    @course.save!

    attachment_model uploaded_data: default_uploaded_data
    @attachment.update_attribute(:locked, true)
    @attachment.reload
    expect(@attachment.locked_for?(@teacher, :check_policies => true)).to be_falsey
  end

  describe 'local storage' do
    it 'should properly sanitie a filename containing a slash' do
      local_storage!
      course_factory
      a = attachment_model(filename: 'ENGL_100_/_ENGL_200.csv')
      expect(a.filename).to eql('ENGL_100___ENGL_200.csv')
    end

    it 'should still properly escape the same filename on s3' do
      s3_storage!
      course_factory
      a = attachment_model(filename: 'ENGL_100_/_ENGL_200.csv')
      expect(a.filename).to eql('ENGL_100_%2F_ENGL_200.csv')
    end
  end

  describe '#ajax_upload_params' do
    it 'returns the attachment filename in the upload params' do
      attachment_model filename: 'test.txt'
      pseudonym @user
      json = @attachment.ajax_upload_params(@user.pseudonym, '', '')
      expect(json[:upload_params]['Filename']).to eq 'test.txt'
    end
  end

  describe 'copy_to_folder!' do
    before(:once) do
      attachment_model filename: 'test.txt'
      @folder = @context.folders.create! name: 'over there'
    end

    it 'copies a file into a folder' do
      dup = @attachment.copy_to_folder!(@folder)
      expect(dup.root_attachment).to eq @attachment
      expect(dup.display_name).to eq 'test.txt'
    end

    it "handles duplicates" do
      attachment_model filename: 'test.txt', folder: @folder
      dup = @attachment.copy_to_folder!(@folder)
      expect(dup.root_attachment).to eq @attachment
      expect(dup.display_name).not_to eq 'test.txt'
    end
  end
end
