# coding: utf-8
#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
      lambda{attachment_model(:context => nil)}.should raise_error(ActiveRecord::RecordInvalid, /Context/)
    end

  end

  context "default_values" do
    it "should set the display name to the filename if it is nil" do
      attachment_model(:display_name => nil)
      @attachment.display_name.should eql(@attachment.filename)
    end

    context "scribd_mime_type_id" do
      it "should get set given extension" do
        Attachment.clear_cached_mime_ids
        scribd_mime_type_model(:extension => 'pdf')
        @course = course_model

        @attachment = @course.attachments.build(:filename => 'some_file.pdf')
        @attachment.content_type = ''
        @attachment.save!
        @attachment.scribd_mime_type.should eql(@scribd_mime_type)
      end

      it "should get set given content_type" do
        Attachment.clear_cached_mime_ids
        scribd_mime_type_model(:name => 'application/pdf')
        @course = course_model

        @attachment = @course.attachments.build(:filename => 'some_file')
        @attachment.content_type = 'application/pdf'
        @attachment.save!
        @attachment.scribd_mime_type.should eql(@scribd_mime_type)
      end

      it "should prefer using content_type over extension" do
        Attachment.clear_cached_mime_ids
        mime_type_pdf = scribd_mime_type_model(:name => 'application/pdf')
        mime_type_doc = scribd_mime_type_model(:extension => 'doc')
        @course = course_model

        @attachment = @course.attachments.build(:filename => 'some_file.doc')
        @attachment.content_type = 'application/pdf'
        @attachment.save!
        @attachment.scribd_mime_type.should eql(mime_type_pdf)
      end

      it "should not get set for html content despite extension" do
        ['text/html', 'application/xhtml+xml', 'application/xml', 'text/xml'].each do |content_type|
          # make sure mime type exists so we'd otherwise have a chance to set it
          mime_type_doc = scribd_mime_type_model(:extension => 'doc')
          mime_type_html = scribd_mime_type_model(:name => content_type)

          @course = course_model
          @attachment = @course.attachments.build(:filename => 'some_file.doc')
          @attachment.content_type = content_type
          @attachment.save!
          @attachment.scribd_mime_type.should be_nil
        end
      end
    end

  end

  it "should be scribdable if scribd_mime_type_id is set" do
    scribdable_attachment_model
    @attachment.should be_scribdable
  end

  context "authenticated_s3_url" do
    before do
      local_storage!
    end

    it "should return http as the protocol by default" do
      course_model
      attachment_with_context(@course)
      @attachment.authenticated_s3_url.should match(/^http:\/\//)
    end

    it "should return the protocol if specified" do
      course_model
      attachment_with_context(@course)
      @attachment.authenticated_s3_url(:secure => true).should match(/^https:\/\//)
    end
  end

  context "scribdable_context" do
    it "should be a scribdable_context if the context is Course" do
      course_model
      attachment_with_context(@course)
      @attachment.send(:scribdable_context?).should be_true
    end

    it "should be a scribdable_context if the context is Group" do
      group_model
      attachment_with_context(@group)
      @attachment.send(:scribdable_context?).should be_true
    end

    it "should be a scribdable_context if the context is User" do
      user_model
      attachment_with_context(@user)
      @attachment.context = @user
      @attachment.context.should be_is_a(User)
      @attachment.send(:scribdable_context?).should be_true
    end

    it "should not be a scribdable_context for non-scribdable contexts (like an Account, for example)" do
      account_model
      attachment_with_context(@account)
      @attachment.context = @account
      @attachment.context.should be_is_a(Account)
      @attachment.send(:scribdable_context?).should be_false
    end

  end

  context "crocodoc" do
    before do
      PluginSetting.create! :name => 'crocodoc',
                            :settings => { :api_key => "blahblahblahblahblah" }
      Crocodoc::API.any_instance.stubs(:upload).returns 'uuid' => '1234567890'
    end

    it "crocodocable?" do
      crocodocable_attachment_model
      @attachment.should be_crocodocable
    end

    it "should not submit to auto-submit to scribd if a crocodoc is present" do
      expects_job_with_tag('Attachment#submit_to_scribd!', 0) do
        attachment_model(:content_type => 'application/pdf', :submission_attachment => true)
        @attachment.after_attachment_saved
      end

      expects_job_with_tag('Attachment#submit_to_scribd!') do
        scribd_mime_type_model(:extension => 'odt', :name => 'openoffice')
        attachment_model(:content_type => 'openoffice')
        @attachment.crocodocable?.should_not be_true
        @attachment.after_attachment_saved
      end
    end

    it "should submit to crocodoc" do
      crocodocable_attachment_model
      @attachment.crocodoc_available?.should be_false
      @attachment.submit_to_crocodoc

      @attachment.crocodoc_available?.should be_true
      @attachment.crocodoc_document.uuid.should == '1234567890'
    end

    it "should spawn a delayed job to retry failed uploads (once)" do
      Crocodoc::API.any_instance.stubs(:upload).returns 'error' => 'blah'
      crocodocable_attachment_model

      expects_job_with_tag('Attachment#submit_to_crocodoc', 1) do
        @attachment.submit_to_crocodoc
      end

      expects_job_with_tag('Attachment#submit_to_crocodoc', 0) do
        @attachment.submit_to_crocodoc(2)
      end
    end

    it "should submit to scribd if crocodoc fails to convert" do
      crocodocable_attachment_model
      @attachment.submit_to_crocodoc

      Crocodoc::API.any_instance.stubs(:status).returns [
        {'uuid' => '1234567890', 'status' => 'ERROR'}
      ]

      expects_job_with_tag('Attachment.submit_to_scribd') {
        CrocodocDocument.update_process_states
      }
    end
  end

  it "should set the uuid" do
    attachment_model
    @attachment.uuid.should_not be_nil
  end

  context "workflow" do
    before do
      attachment_model
    end

    it "should default to pending_upload" do
      @attachment.state.should eql(:pending_upload)
    end

    it "should be able to upload and record the submitted_to_scribd_at" do
      time = Time.now
      @attachment.upload!
      @attachment.submitted_to_scribd_at.to_i.should be_close(time.to_i, 2)
      @attachment.state.should eql(:processing)
    end

    it "should be able to take a processing object and complete its process" do
      attachment_model(:workflow_state => 'processing')
      @attachment.process!
      @attachment.state.should eql(:processed)
    end

    it "should be able to take a new object and bypass upload with process" do
      @attachment.process!
      @attachment.state.should eql(:processed)
    end

    it "should be able to recycle a processed object and re-upload it" do
      attachment_model(:workflow_state => 'processed')
      @attachment.recycle
      @attachment.state.should eql(:pending_upload)
    end
  end

  context "submit_to_scribd!" do
    before do
      ScribdAPI.stubs(:upload).returns(UUIDSingleton.instance.generate)
    end

    describe "submit_to_scribd job" do
      it "should queue for scribdable types" do
        expects_job_with_tag('Attachment#submit_to_scribd!') do
          scribdable_attachment_model
          @attachment.after_attachment_saved
        end
        @attachment.should be_pending_upload
      end

      it "should not queue for non-scribdable types" do
        expects_job_with_tag('Attachment#submit_to_scribd!', 0) do
          attachment_model
          @attachment.after_attachment_saved
        end
        @attachment.should be_processed
      end

      it "should not queue for non-root attachments" do
        expects_job_with_tag('Attachment#submit_to_scribd!', 1) do
          @attachment1 = scribdable_attachment_model
          @attachment1.after_attachment_saved
          @attachment2 = scribdable_attachment_model
          # normally done by uploaded_data= in attachment_fu
          @attachment2.root_attachment = @attachment1
          @attachment2.after_attachment_saved
        end
        @attachment1.should be_pending_upload
        @attachment2.should be_processed
      end

      describe "scribd submit filtering" do
        it "should still submit if the attachment is tagged" do
          Attachment.stubs(:filtering_scribd_submits?).returns(true)
          expects_job_with_tag('Attachment#submit_to_scribd!') do
            scribd_mime_type_model(:extension => 'pdf')
            attachment_model(:content_type => 'application/pdf', :submission_attachment => true)
            @attachment.after_attachment_saved
          end
          @attachment.should be_pending_upload
        end

        it "should skip submit if the attachment isn't tagged" do
          Attachment.stubs(:filtering_scribd_submits?).returns(true)
          expects_job_with_tag('Attachment#submit_to_scribd!', 0) do
            scribdable_attachment_model
            @attachment.after_attachment_saved
          end
          @attachment.should be_processed
        end
      end
    end

    it "should upload scribdable attachments" do
      scribdable_attachment_model
      @doc_obj = Scribd::Document.new
      ScribdAPI.expects(:upload).returns(@doc_obj)
      @doc_obj.stubs(:thumbnail).returns("the url to the scribd doc thumbnail")
      @attachment.submit_to_scribd!.should be_true
      @attachment.scribd_doc.should eql(@doc_obj)
      @attachment.state.should eql(:processing)
    end

    it "should bypass non-scridbable attachments" do
      attachment_model
      @attachment.should_not be_scribdable
      Scribd::API.instance.expects(:user=).never
      ScribdAPI.expects(:upload).never
      @attachment.submit_to_scribd!.should be_true
      @attachment.state.should eql(:processed)
    end

    it "should not mess with attachments outside the pending_upload state" do
      Scribd::API.instance.expects(:user=).never
      ScribdAPI.expects(:upload).never
      attachment_model(:workflow_state => 'processing')
      @attachment.submit_to_scribd!.should be_false
      attachment_model(:workflow_state => 'processed')
      @attachment.submit_to_scribd!.should be_false
    end

    it "should use the root attachment scribd doc" do
      Scribd::Document.any_instance.stubs(:destroy).returns(true)
      a1 = attachment_model(:workflow_state => 'processing')
      a2 = attachment_model(:workflow_state => 'processing', :root_attachment => a1)
      a2.root_attachment.should == a1
      a1.scribd_doc = doc = Scribd::Document.new
      a2.scribd_doc.should == doc
      a2.destroy
      a1.scribd_doc.should == doc
    end

    it "should not send the secret password via to_json" do
      attachment_model
      @attachment.scribd_doc = Scribd::Document.new
      @attachment.scribd_doc.doc_id = 'asdf'
      @attachment.scribd_doc.secret_password = 'password'
      res = JSON.parse(@attachment.to_json)
      res['attachment'].should_not be_nil
      res['attachment']['scribd_doc'].should_not be_nil
      res['attachment']['scribd_doc']['attributes'].should_not be_nil
      res['attachment']['scribd_doc']['attributes']['doc_id'].should eql('asdf')
      res['attachment']['scribd_doc']['attributes']['secret_password'].should eql('')
      @attachment.scribd_doc.doc_id.should eql('asdf')
      @attachment.scribd_doc.secret_password.should eql('password')
    end
  end

  context "scribd cleanup" do
    before do
      ScribdAPI.stubs(:enabled?).returns(true)
    end

    after do
      ScribdAPI.unstub(:enabled?)
    end

    def fake_scribd_doc(doc_id = String.random(8))
      scribd_doc = Scribd::Document.new
      scribd_doc.doc_id = doc_id
      scribd_doc.secret_password = 'asdf'
      scribd_doc.access_key = 'jkl;'
      scribd_doc
    end

    def attachment_with_scribd_doc(doc = fake_scribd_doc, opts = {})
      att = attachment_model(opts)
      att.scribd_doc = doc
      att.save!
      att
    end

    describe "clones with scribd" do
      it 'should not copy scribd info on clone' do
        a = attachment_with_scribd_doc(fake_scribd_doc('zero'))
        course
        new_a = a.clone_for(@course)
        new_a.save!
        new_a.read_attribute(:scribd_doc).should be_nil
        new_a.scribd_doc.id.should == a.scribd_doc.id
      end
    end

    describe "related_attachments" do
      it "should include the root attachment" do
        @root = attachment_model
        @child = attachment_model :root_attachment => @root
        @child.related_attachments.map(&:id).should == [@root.id]
      end

      it "should include child attachments" do
        @root = attachment_model
        @child = attachment_model :root_attachment => @root
        @root.related_attachments.map(&:id).should == [@child.id]
      end

      it "should include sibling attachments" do
        @root = attachment_model
        @child1 = attachment_model :root_attachment => @root
        @child2 = attachment_model :root_attachment => @root
        @child1.related_attachments.map(&:id).sort.should == [@root.id, @child2.id].sort
      end
    end

    describe "delete_scribd_doc" do
      it "should not delete the scribd doc when the attachment is destroyed" do
        @att = attachment_with_scribd_doc(fake_scribd_doc('zero'))
        @att.scribd_doc.expects(:destroy).never
        @att.destroy
        @att.file_state.should eql 'deleted'
        @att.workflow_state.should eql 'pending_upload'
        @att.read_attribute(:scribd_doc).should_not be_nil
      end

      it "should do nothing for non-root attachments" do
        @root = attachment_with_scribd_doc(fake_scribd_doc('zero'))
        @child = attachment_model(root_attachment: @root)
        @child.scribd_doc.expects(:destroy).never
        @child.scribd_doc.should == @root.scribd_doc
        @child.delete_scribd_doc
      end

      it "should delete scribd_doc" do
        @root = attachment_with_scribd_doc(fake_scribd_doc('zero'))
        @root.scribd_doc.expects(:destroy).once.returns(true)
        @root.read_attribute(:scribd_doc).should_not be_nil
        @root.delete_scribd_doc
        @root.read_attribute(:scribd_doc).should be_nil
      end
    end

    describe "check_rerender_scribd_doc" do
      before do
        scribd_mime_type_model(:extension => 'docx')
      end

      it "should resubmit a deleted scribd doc" do
        @attachment = attachment_with_scribd_doc(fake_scribd_doc, :filename => 'file.docx', :scribd_attempts => 3)
        @attachment.scribd_doc.expects(:destroy).once.returns(true)
        @attachment.delete_scribd_doc
        expect {
          @attachment.check_rerender_scribd_doc
        }.to change(Delayed::Job, :count).by(1)
        Delayed::Job.find_by_tag('Attachment#submit_to_scribd!').should_not be_nil
        @attachment.should be_pending_upload
        @attachment.scribd_attempts.should == 0
      end

      it "should not queue up duplicate render requests for the same document" do
        @attachment = attachment_model(:filename => 'file.docx', :workflow_state => 'deleted')
        expect { @attachment.check_rerender_scribd_doc }.to change(Delayed::Job, :count).by(1)
        expect { @attachment.check_rerender_scribd_doc }.to change(Delayed::Job, :count).by(0)
      end

      it "should do nothing if a scribd_doc already exists" do
        @attachment = attachment_with_scribd_doc(fake_scribd_doc, :filename => 'file.docx')
        expect {
          @attachment.check_rerender_scribd_doc
        }.to change(Delayed::Job, :count).by(0)
      end

      it "should be invoked on record_inline_view" do
        @attachment = attachment_model(:filename => 'file.docx', :workflow_state => 'deleted')
        expect {
          @attachment.record_inline_view
        }.to change(Delayed::Job, :count).by(1)
      end

      it "should do nothing on non-scribdable types" do
        @attachment = attachment_model(:filename => 'file.lolcats')
        expect {
          @attachment.check_rerender_scribd_doc
        }.to change(Delayed::Job, :count).by(0)
      end
    end

    describe "scribd_render_url" do
      before do
        scribd_mime_type_model(:extension => 'docx')
      end

      it "should return a url to request scribd rerendering" do
        @attachment = attachment_model(:filename => 'file.docx', :workflow_state => 'deleted')
        @attachment.scribd_render_url.should == "/#{@attachment.context_url_prefix}/files/#{@attachment.id}/scribd_render"
      end

      it "should return nil if the scribd doc isn't missing" do
        @attachment = attachment_with_scribd_doc
        @attachment.scribd_render_url.should be_nil
      end
    end
  end

  context "conversion_status" do
    before(:each) do
      @document = Scribd::Document.new
      @document.stubs(:conversion_status).returns(:status_from_scribd)
      Scribd::API.instance.stubs(:user=).returns(true)
      ScribdAPI.stubs(:upload).returns(@document)
      ScribdAPI.stubs(:enabled?).returns(true)
    end

    it "should have a default conversion_status of :not_submitted for attachments that haven't been submitted" do
      attachment_model
      @attachment.conversion_status.should eql('NOT SUBMITTED')
    end

    it "should ask Scribd for the status" do
      scribdable_attachment_model
      @doc_obj = Scribd::Document.new
      @doc_obj.expects(:conversion_status).returns(:status_from_scribd)
      ScribdAPI.expects(:upload).returns(@doc_obj)
      @doc_obj.stubs(:thumbnail).returns("the url to the scribd doc thumbnail")
      @attachment.submit_to_scribd!
      @attachment.query_conversion_status!
    end

    it "should not ask Scribd for the status" do
      scribdable_attachment_model
      @doc_obj = Scribd::Document.new
      @doc_obj.expects(:conversion_status).never
      ScribdAPI.expects(:upload).returns(@doc_obj)
      @doc_obj.stubs(:thumbnail).returns("the url to the scribd doc thumbnail")
      @attachment.submit_to_scribd!
      @attachment.conversion_status.should == "PROCESSING"
    end

  end

  context "download_url" do
    before do
      Scribd::API.instance.stubs(:user=).returns(true)
      @doc = mock('Scribd Document', :download_url => 'some url')
      Scribd::Document.stubs(:find).returns(@doc)
    end
  end

  context "named scopes" do
    it "should have a scope for all scribdable attachments, regardless their state" do
      (1..3).each { attachment_model }
      (1..3).each { scribdable_attachment_model }
      Attachment.scribdable?.size.should eql(3)
      Attachment.all.size.should eql(6)
      Attachment.scribdable?.each {|m| m.should be_scribdable}
    end

    it "should have a scope for uploadable models, all models that are in the pending_upload state" do
      attachment_model
      attachments = [@attachment]
      @attachment.submit_to_scribd!
      attachment_model
      attachments << @attachment
      scribdable_attachment_model
      attachments << @attachment
      Attachment.all.size.should eql(3)
      Attachment.uploadable.size.should eql(2)
      Attachment.uploadable.should be_include(Attachment.find(attachments[1].id))
      Attachment.uploadable.should be_include(Attachment.find(attachments[2].id))
    end

    context "by_content_types" do
      before do
        course_model
        @gif = attachment_model :context => @course, :content_type => 'image/gif'
        @jpg = attachment_model :context => @course, :content_type => 'image/jpeg'
        @weird = attachment_model :context => @course, :content_type => "%/what's this"
      end

      it "should match type" do
        @course.attachments.by_content_types(['image']).pluck(:id).sort.should == [@gif.id, @jpg.id].sort
      end

      it "should match type/subtype" do
        @course.attachments.by_content_types(['image/gif']).pluck(:id).should == [@gif.id]
        @course.attachments.by_content_types(['image/gif', 'image/jpeg']).pluck(:id).sort.should == [@gif.id, @jpg.id].sort
      end

      it "should escape sql and wildcards" do
        @course.attachments.by_content_types(['%']).pluck(:id).should == [@weird.id]
        @course.attachments.by_content_types(["%/what's this"]).pluck(:id).should == [@weird.id]
        @course.attachments.by_content_types(["%/%"]).pluck(:id).should == []
      end
    end
  end

  context "uploaded_data" do
    it "should create with uploaded_data" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      a.filename.should eql("doc.doc")
    end

    context "uploading and db transactions" do
      self.use_transactional_fixtures = false

      before do
        attachment_model(:context => Account.default.groups.create!, :filename => 'test.mp4', :content_type => 'video')
      end

      after do
        truncate_table(Attachment)
        truncate_table(Folder)
        truncate_table(Group)
      end

      it "should delay upload until the #save transaction is committed" do
        @attachment.uploaded_data = default_uploaded_data
        @attachment.connection.expects(:after_transaction_commit).once
        @attachment.expects(:touch_context_if_appropriate).never
        @attachment.expects(:build_media_object).never
        @attachment.save
      end

      it "should upload immediately when in a non-joinable transaction" do
        Attachment.connection.transaction(:joinable => false) do
          @attachment.uploaded_data = default_uploaded_data
          Attachment.connection.expects(:after_transaction_commit).never
          @attachment.expects(:touch_context_if_appropriate)
          @attachment.expects(:build_media_object)
          @attachment.save
        end
      end
    end
  end

  context "build_media_object" do
    before :each do
      @course = course
      @attachment = @course.attachments.build(:filename => 'foo.mp4')
      @attachment.content_type = 'video'
      @attachment.stubs(:downloadable?).returns(true)
    end

    it "should be called automatically upon creation" do
      @attachment.expects(:build_media_object).once
      @attachment.save!
    end

    it "should create a media object for videos" do
      MediaObject.expects(:send_later_enqueue_args).once
      @attachment.save!
    end

    it "should delay the creation of the media object by attachment_build_media_object_delay_seconds" do
      now = Time.now
      Time.stubs(:now).returns(now)
      Setting.stubs(:get).returns(nil)
      Setting.expects(:get).with('attachment_build_media_object_delay_seconds', '10').once.returns('25')
      track_jobs do
        @attachment.save!
      end

      MediaObject.count.should == 0
      job = created_jobs.first
      job.tag.should == 'MediaObject.add_media_files'
      job.run_at.to_i.should == (now + 25.seconds).to_i
    end

    it "should not create a media object in a skip_media_object_creation block" do
      Attachment.skip_media_object_creation do
        MediaObject.expects(:send_later_enqueue_args).times(0)
        @attachment.save!
      end
    end

    it "should not create a media object for images" do
      @attachment.filename = 'foo.png'
      @attachment.content_type = 'image/png'
      @attachment.expects(:build_media_object).once
      MediaObject.expects(:send_later_enqueue_args).times(0)
      @attachment.save!
    end

    it "should create a media object *after* a direct-to-s3 upload" do
      MediaObject.expects(:send_later_enqueue_args).never
      @attachment.workflow_state = 'unattached'
      @attachment.file_state = 'deleted'
      @attachment.save!
      MediaObject.expects(:send_later_enqueue_args).once
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
      media_object.should_not be_deleted
      media_object.attachment_id.should be_nil
    end
  end

  context "destroy" do
    it "should not actually destroy" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      a.filename.should eql("doc.doc")
      a.destroy
      a.should_not be_frozen
      a.should be_deleted
    end

    it "should not probably be possible to actually destroy... somehow" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      a.filename.should eql("doc.doc")
      a.destroy
      a.should_not be_frozen
      a.should be_deleted
      a.destroy!
      a.should be_frozen
    end

    it "should not show up in the context list after being destroyed" do
      @course = course
      @course.should_not be_nil
      a = attachment_model(:uploaded_data => default_uploaded_data, :context => @course)
      a.filename.should eql("doc.doc")
      a.context.should eql(@course)
      a.destroy
      a.should_not be_frozen
      a.should be_deleted
      @course.attachments.should be_include(a)
      @course.attachments.active.should_not be_include(a)
    end

    it "should still destroy without error if file data is lost" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      a.stubs(:downloadable?).returns(false)
      a.destroy
      a.should be_deleted
    end
  end

  context "destroy!" do
    it "should not delete the s3 object, even here" do
      s3_storage!
      a = attachment_model
      s3object = a.s3object
      s3object.expects(:delete).never
      a.destroy!
    end
  end

  context "inferred display name" do
    it "should take a normal filename and use it as a diplay name" do
      a = attachment_model(:filename => 'normal_name.ppt')
      a.display_name.should eql('normal_name.ppt')
    end

    it "should take a normal filename with spaces and convert the underscores to spaces" do
      a = attachment_model(:filename => 'normal_name.ppt')
      a.display_name.should eql('normal_name.ppt')
    end

    it "should preserve case" do
      a = attachment_model(:filename => 'Normal_naMe.ppt')
      a.display_name.should eql('Normal_naMe.ppt')
    end

    it "should split long names with dashes" do
      a = attachment_model(:filename => 'this is a long name, over 30 characters long.ppt')
      a.display_name.should eql('this is a long name, over 30 characters long.ppt')
    end

    it "shouldn't try to break up very large words" do
      a = attachment_model(:filename => 'A long Bulgarian word is neprotifconstitutiondeistveiteneprotifconstitutiondeistveite')
      a.display_name.should eql('A long Bulgarian word is neprotifconstitutiondeistveiteneprotifconstitutiondeistveite')
    end

    it "should truncate filenames that are just too freaking big" do
      fn = Attachment.new.sanitize_filename('My new study guide or case study on this evolution on monkeys even in that land of costa rica somewhere my own point of  view going along with the field experiment I would say or try out is to put them not in wet areas like costa rico but try and put it so its not so long.docx')
      fn.should eql("My+new+study+guide+or+case+study+on+this+evolution+on+monkeys+even+in+that+land+of+costa+rica+somewhere+my+own.docx")
    end
  end

  context "clone_for" do
    it "should clone to another context" do
      a = attachment_model(:filename => "blech.ppt")
      course
      new_a = a.clone_for(@course)
      new_a.context.should_not eql(a.context)
      new_a.filename.should eql(a.filename)
      new_a.root_attachment_id.should eql(a.id)
    end

    it "should link the thumbnail" do
      a = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
      a.thumbnail.should_not be_nil
      course
      new_a = a.clone_for(@course)
      new_a.thumbnail.should_not be_nil
      new_a.thumbnail_url.should_not be_nil
      new_a.thumbnail_url.should == a.thumbnail_url
    end

    it "should not create root_attachment_id cycles or self-references" do
      a = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
      a.root_attachment_id.should be_nil
      coursea = @course
      @context = courseb = course
      b = a.clone_for(courseb, nil, :overwrite => true)
      b.save
      b.context.should == courseb
      b.root_attachment.should == a

      new_a = b.clone_for(coursea, nil, :overwrite => true)
      new_a.should == a
      new_a.root_attachment_id.should be_nil

      new_b = new_a.clone_for(courseb, nil, :overwrite => true)
      new_b.root_attachment_id.should == a.id

      new_b = b.clone_for(courseb, nil, :overwrite => true)
      new_b.root_attachment_id.should == a.id

      @context = coursec = course
      c = b.clone_for(coursec, nil, :overwrite => true)
      c.root_attachment.should == a

      new_a = c.clone_for(coursea, nil, :overwrite => true)
      new_a.should == a
      new_a.root_attachment_id.should be_nil

      # pretend b's content changed so it got disconnected
      b.update_attribute(:root_attachment_id, nil)
      new_b = b.clone_for(courseb, nil, :overwrite => true)
      new_b.root_attachment_id.should be_nil
    end

    it "should maintain namespace across clones" do
      a = attachment_model(uploaded_data: stub_png_data, content_type: 'image/png')
      a.root_attachment_id.should be_nil
      coursea = @course
      @context = courseb = course

      # emulate the situation where a namespace doesn't match what
      # infer_namespace now returns
      a.update_attribute(:namespace, "test_ns")

      b = a.clone_for(courseb, nil, overwrite: true)
      b.save
      b.root_attachment.should == a
      b.namespace.should == "test_ns"

      new_a = b.clone_for(coursea, nil, overwrite: true)
      new_a.save
      new_a.should == a
      new_a.namespace.should == "test_ns"
    end
  end

  context "adheres_to_policy" do
    it "should not allow unauthorized users to read files" do
      user = user_model
      a = attachment_model
      @course.update_attribute(:is_public, false)
      a.grants_right?(user, nil, :read).should eql(false)
    end

    it "should allow anonymous access for public contexts" do
      user = user_model
      a = attachment_model
      @course.update_attribute(:is_public, true)
      a.grants_right?(user, nil, :read).should eql(false)
    end

    it "should allow students to read files" do
      a = attachment_model
      @course.update_attribute(:is_public, false)
      user = user_model
      @course.offer
      @course.enroll_student(user).accept
      a.reload
      a.grants_right?(user, nil, :read).should eql(true)
    end

    it "should allow students to download files" do
      a = attachment_model
      @course.offer
      @course.update_attribute(:is_public, false)
      user = user_model
      @course.enroll_student(user).accept
      a.reload
      a.grants_right?(user, nil, :download).should eql(true)
    end

    it "should allow students to read (but not download) locked files" do
      a = attachment_model
      a.update_attribute(:locked, true)
      @course.offer
      @course.update_attribute(:is_public, false)
      user = user_model
      @course.enroll_student(user).accept
      a.reload
      a.grants_right?(user, nil, :read).should eql(true)
      a.grants_right?(user, nil, :download).should eql(false)
    end

    it "should allow user access based on 'file_access_user_id' and 'file_access_expiration' in the session" do
      a = attachment_model
      @course.offer
      @course.update_attribute(:is_public, false)
      user = user_model
      @course.enroll_student(user).accept
      a.reload
      a.grants_right?(nil, nil, :read).should eql(false)
      a.grants_right?(nil, nil, :read).should eql(false)
      a.grants_right?(nil, {'file_access_user_id' => user.id, 'file_access_expiration' => 1.hour.from_now.to_i}, :read).should eql(true)
      a.grants_right?(nil, {'file_access_user_id' => user.id, 'file_access_expiration' => 1.hour.from_now.to_i}, :download).should eql(true)
    end
    it "should not allow user access based on incorrect 'file_access_user_id' in the session" do
      a = attachment_model
      @course.offer
      @course.update_attribute(:is_public, false)
      user = user_model
      @course.enroll_student(user).accept
      a.reload
      a.grants_right?(nil, nil, :read).should eql(false)
      a.grants_right?(nil, nil, :read).should eql(false)
      a.grants_right?(nil, {'file_access_user_id' => 0, 'file_access_expiration' => 1.hour.from_now.to_i}, :read).should eql(false)
    end
    it "should not allow user access based on incorrect 'file_access_expiration' in the session" do
      a = attachment_model
      @course.offer
      @course.update_attribute(:is_public, false)
      user = user_model
      @course.enroll_student(user).accept
      a.reload
      a.grants_right?(nil, nil, :read).should eql(false)
      a.grants_right?(nil, nil, :read).should eql(false)
      a.grants_right?(nil, {'file_access_user_id' => user.id, 'file_access_expiration' => 1.minute.ago.to_i}, :read).should eql(false)
    end
  end

  context "duplicate handling" do
    before(:each) do
      course_model
      @a1 = attachment_with_context(@course, :display_name => "a1")
      @a2 = attachment_with_context(@course, :display_name => "a2")
      @a = attachment_with_context(@course)
    end

    it "should handle overwriting duplicates" do
      @a.display_name = 'a1'
      deleted = @a.handle_duplicates(:overwrite)
      @a.file_state.should == 'available'
      @a1.reload
      @a1.file_state.should == 'deleted'
      deleted.should == [ @a1 ]
    end

    it "should handle renaming duplicates" do
      @a.display_name = 'a1'
      deleted = @a.handle_duplicates(:rename)
      deleted.should be_empty
      @a.file_state.should == 'available'
      @a1.reload
      @a1.file_state.should == 'available'
      @a.display_name.should == 'a1-1'
    end

    it "should update ContentTags when overwriting" do
      mod = @course.context_modules.create!(:name => "some module")
      tag1 = mod.add_item(:id => @a1.id, :type => 'attachment')
      tag2 = mod.add_item(:id => @a2.id, :type => 'attachment')
      mod.save!

      @a.display_name = 'a1'
      @a.handle_duplicates(:overwrite)
      tag1.reload
      tag1.should be_active
      tag1.content_id.should == @a.id

      @a2.destroy
      tag2.reload
      tag2.should be_deleted
    end
  end

  describe "make_unique_filename" do
    it "should find a unique name for files" do
      existing_files = %w(a.txt b.txt c.txt)
      Attachment.make_unique_filename("d.txt", existing_files).should == "d.txt"
      existing_files.should_not be_include(Attachment.make_unique_filename("b.txt", existing_files))

      existing_files = %w(/a/b/a.txt /a/b/b.txt /a/b/c.txt)
      Attachment.make_unique_filename("/a/b/d.txt", existing_files).should == "/a/b/d.txt"
      new_name = Attachment.make_unique_filename("/a/b/b.txt", existing_files)
      existing_files.should_not be_include(new_name)
      new_name.should match(%r{^/a/b/b[^.]+\.txt})
    end
  end

  context "cacheable s3 urls" do
    before(:each) do
      course_model
    end

    it "should include response-content-disposition" do
      attachment = attachment_with_context(@course, :display_name => 'foo')
      attachment.expects(:authenticated_s3_url).at_least(0) # allow other calls due to, e.g., save
      attachment.expects(:authenticated_s3_url).with(has_entry(:response_content_disposition => %(attachment; filename="foo"; filename*=UTF-8''foo)))
      attachment.expects(:authenticated_s3_url).with(has_entry(:response_content_disposition => %(inline; filename="foo"; filename*=UTF-8''foo)))
      attachment.cacheable_s3_inline_url
      attachment.cacheable_s3_download_url
    end

    it "should use the display_name, not filename, in the response-content-disposition" do
      attachment = attachment_with_context(@course, :filename => 'bar', :display_name => 'foo')
      attachment.expects(:authenticated_s3_url).at_least(0) # allow other calls due to, e.g., save
      attachment.expects(:authenticated_s3_url).with(has_entry(:response_content_disposition => %(attachment; filename="foo"; filename*=UTF-8''foo)))
      attachment.cacheable_s3_inline_url
    end

    it "should http quote the filename in the response-content-disposition if necessary" do
      attachment = attachment_with_context(@course, :display_name => 'fo"o')
      attachment.expects(:authenticated_s3_url).at_least(0) # allow other calls due to, e.g., save
      attachment.expects(:authenticated_s3_url).with(has_entry(:response_content_disposition => %(attachment; filename="fo\\"o"; filename*=UTF-8''fo%22o)))
      attachment.cacheable_s3_inline_url
    end

    it "should sanitize filename with iconv" do
      a = attachment_with_context(@course, :display_name => "糟糕.pdf")
      sanitized_filename = Iconv.conv("ASCII//TRANSLIT//IGNORE", "UTF-8", a.display_name)
      a.expects(:authenticated_s3_url).at_least(0)
      a.expects(:authenticated_s3_url).with(has_entry(:response_content_disposition => %(attachment; filename="#{sanitized_filename}"; filename*=UTF-8''%E7%B3%9F%E7%B3%95.pdf)))
      a.cacheable_s3_inline_url
    end

    it "should escape all non-alphanumeric characters in the utf-8 filename" do
      attachment = attachment_with_context(@course, :display_name => '"This file[0] \'{has}\' \# awesome `^<> chars 100%,|<-pipe"')
      attachment.expects(:authenticated_s3_url).at_least(0) # allow other calls due to, e.g., save
      attachment.expects(:authenticated_s3_url).with(has_entry(:response_content_disposition => %(attachment; filename="\\\"This file[0] '{has}' \\# awesome `^<> chars 100%,|<-pipe\\\""; filename*=UTF-8''%22This%20file%5B0%5D%20%27%7Bhas%7D%27%20%5C%23%20awesome%20%60%5E%3C%3E%20chars%20100%25%2C%7C%3C%2Dpipe%22)))
      attachment.cacheable_s3_inline_url
    end
  end

  context "root_account_id" do
    before do
      account_model
      course_model(:account => @account)
      @a = attachment_with_context(@course)
    end

    it "should return account id for normal namespaces" do
      @a.namespace = "account_#{@account.id}"
      @a.root_account_id.should == @account.id
    end

    it "should return account id for localstorage namespaces" do
      @a.namespace = "_localstorage_/#{@account.file_namespace}"
      @a.root_account_id.should == @account.id
    end

    it "should immediately infer the namespace if not yet set" do
      Attachment.domain_namespace = nil
      @a = Attachment.new(:context => @course)
      @a.should be_new_record
      @a.read_attribute(:namespace).should be_nil
      @a.namespace.should_not be_nil
      @a.read_attribute(:namespace).should_not be_nil
      @a.root_account_id.should == @account.id
    end

    it "should not infer the namespace if it's not a new record" do
      Attachment.domain_namespace = nil
      attachment_model(:context => submission_model)
      @attachment.should_not be_new_record
      @attachment.read_attribute(:namespace).should be_nil
      @attachment.namespace.should be_nil
      @attachment.read_attribute(:namespace).should be_nil
    end
  end

  context "encoding detection" do
    it "should include the charset when appropriate" do
      a = Attachment.new
      a.content_type = 'text/html'
      a.content_type_with_encoding.should == 'text/html'
      a.encoding = ''
      a.content_type_with_encoding.should == 'text/html'
      a.encoding = 'UTF-8'
      a.content_type_with_encoding.should == 'text/html; charset=UTF-8'
      a.encoding = 'mycustomencoding'
      a.content_type_with_encoding.should == 'text/html; charset=mycustomencoding'
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
      @attachment.encoding.should be_nil
      @attachment.infer_encoding
      # can't figure out GIF encoding
      @attachment.encoding.should == ''

      attachment_model(:uploaded_data => stub_png_data('blank.txt', "Hello World!"))
      @attachment.encoding.should be_nil
      @attachment.infer_encoding
      @attachment.encoding.should == 'UTF-8'

      attachment_model(:uploaded_data => stub_png_data('blank.txt', "\xc2\xa9 2011"))
      @attachment.encoding.should be_nil
      @attachment.infer_encoding
      @attachment.encoding.should == 'UTF-8'
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should infer scribd mime type regardless of shard" do
      scribd_mime_type_model(:extension => 'pdf')
      attachment_model(:content_type => 'application/pdf')
      @attachment.should be_scribdable
      Attachment.clear_cached_mime_ids
      @shard1.activate do
        # need to create a context on this shard
        @context = course_model(:account => Account.create!)
        attachment_model(:content_type => 'application/pdf')
        @attachment.should be_scribdable
      end
    end

    it "grants rights to owning user even if the user is on a seperate shard" do
      user = nil
      attachments = []

      @shard1.activate do
        user = User.create!
        user.attachments.build.grants_right?(user, nil, :read).should be_true
      end

      @shard2.activate do
        user.attachments.build.grants_right?(user, nil, :read).should be_true
      end

      user.attachments.build.grants_right?(user, nil, :read).should be_true
    end
  end

  context "#change_namespace" do
    before do
      s3_storage!
      @old_account = account_model
      Attachment.domain_namespace = @old_account.file_namespace
      @root = attachment_model
      @child = attachment_model(:root_attachment => @root)
      @new_account = account_model

      @old_object = mock('old object')
      @new_object = mock('new object')
      new_full_filename = @root.full_filename.sub(@root.namespace, @new_account.file_namespace)
      @objects = { @root.full_filename => @old_object, new_full_filename => @new_object }
      @root.bucket.stubs(:objects).returns(@objects)
    end

    it "should fail for non-root attachments" do
      @old_object.expects(:copy_to).never
      expect { @child.change_namespace(@new_account.file_namespace) }.to raise_error
      @root.reload.namespace.should == @old_account.file_namespace
      @child.reload.namespace.should == @root.reload.namespace
    end

    it "should not copy if the destination exists" do
      @new_object.expects(:exists?).returns(true)
      @old_object.expects(:copy_to).never
      @root.change_namespace(@new_account.file_namespace)
      @root.namespace.should == @new_account.file_namespace
      @child.reload.namespace.should == @root.namespace
    end

    it "should rename root attachments and update children" do
      @new_object.expects(:exists?).returns(false)
      @old_object.expects(:copy_to).with(@root.full_filename.sub(@old_account.id.to_s, @new_account.id.to_s), anything)
      @root.change_namespace(@new_account.file_namespace)
      @root.namespace.should == @new_account.file_namespace
      @child.reload.namespace.should == @root.namespace
    end
  end

  context "dynamic thumbnails" do
    let(:sz) { "640x>" }

    before do
      attachment_model(:uploaded_data => stub_png_data)
    end

    it "should use the default size if an unknown size is passed in" do
      @attachment.thumbnail || @attachment.build_thumbnail.save!
      url = @attachment.thumbnail_url(:size => "100x100")
      url.should be_present
      url.should == @attachment.thumbnail.authenticated_s3_url
    end

    it "should generate the thumbnail on the fly" do
      thumb = @attachment.thumbnails.find_by_thumbnail("640x>")
      thumb.should == nil

      @attachment.expects(:create_or_update_thumbnail).with(anything, sz, sz).returns { @attachment.thumbnails.create!(:thumbnail => "640x>", :uploaded_data => stub_png_data) }
      url = @attachment.thumbnail_url(:size => "640x>")
      url.should be_present
      thumb = @attachment.thumbnails.find_by_thumbnail("640x>")
      thumb.should be_present
      url.should == thumb.authenticated_s3_url
    end

    it "should use the existing thumbnail if present" do
      @attachment.expects(:create_or_update_thumbnail).with(anything, sz, sz).returns { @attachment.thumbnails.create!(:thumbnail => "640x>", :uploaded_data => stub_png_data) }
      url = @attachment.thumbnail_url(:size => "640x>")
      @attachment.expects(:create_dynamic_thumbnail).never
      url = @attachment.thumbnail_url(:size => "640x>")
      thumb = @attachment.thumbnails.find_by_thumbnail("640x>")
      url.should be_present
      thumb.should be_present
      url.should == thumb.authenticated_s3_url
    end

    describe 'when its a scribd document' do
      before do
        @attachment.scribd_doc = Scribd::Document.new
        ScribdAPI.expects(:enabled?).times(0)
      end

      it 'returns the cached thumbnail if present' do
        @attachment.cached_scribd_thumbnail = "THUMBNAIL_URL"
        @attachment.thumbnail_url.should == "THUMBNAIL_URL"
      end

      it 'just returns nil if there is no cached thumbnail' do
        @attachment.thumbnail_url.should be_nil
      end
    end
  end

  describe '.allows_thumbnails_for_size' do
    it 'inevitably returns false if there is no size provided' do
      Attachment.allows_thumbnails_of_size?(nil).should be_false
    end

    it 'returns true if the provided size is in the configured dynamic sizes' do
      Attachment.allows_thumbnails_of_size?(Attachment::DYNAMIC_THUMBNAIL_SIZES.first).should be_true
    end

    it 'returns false if the provided size is not in the configured dynamic sizes' do
      Attachment.allows_thumbnails_of_size?('nonsense').should be_false
    end
  end

  context "notifications" do
    before :each do
      course_model(:workflow_state => "available")
      # ^ enrolls @teacher in @course

      # create a student to receive notifications
      @student = user_model
      @student.register!
      e = @course.enroll_student(@student).accept
      @cc = @student.communication_channels.create(:path => "default@example.com")
      @cc.confirm!
      NotificationPolicy.create(:notification => Notification.create!(:name => 'New File Added'), :communication_channel => @cc, :frequency => "immediately")
      NotificationPolicy.create(:notification => Notification.create!(:name => 'New Files Added'), :communication_channel => @cc, :frequency => "immediately")
    end

    it "should send a single-file notification" do
      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')
      @attachment.need_notify.should be_true

      new_time = Time.now + 10.minutes
      Time.stubs(:now).returns(new_time)
      Attachment.do_notifications

      @attachment.reload
      @attachment.need_notify.should_not be_true
      Message.find_by_user_id_and_notification_name(@student.id, 'New File Added').should_not be_nil
    end

    it "should send a batch notification" do
      att1 = attachment_model(:uploaded_data => stub_file_data('file1.txt', nil, 'text/html'), :content_type => 'text/html')
      att2 = attachment_model(:uploaded_data => stub_file_data('file2.txt', nil, 'text/html'), :content_type => 'text/html')
      att3 = attachment_model(:uploaded_data => stub_file_data('file3.txt', nil, 'text/html'), :content_type => 'text/html')
      [att1, att2, att3].each {|att| att.need_notify.should be_true}

      new_time = Time.now + 10.minutes
      Time.stubs(:now).returns(new_time)
      Attachment.do_notifications

      [att1, att2, att3].each {|att| att.reload.need_notify.should_not be_true}
      Message.find_by_user_id_and_notification_name(@student.id, 'New Files Added').should_not be_nil
    end

    it "should not notify before a file finishes uploading" do
      # it's weird, but file_state is 'deleted' until the upload completes, when it is changed to 'available'
      attachment_model(:file_state => 'deleted', :content_type => 'text/html')
      @attachment.need_notify.should_not be_true
    end

    it "should postpone notification of a batch judged to be in-progress" do
      att1 = attachment_model(:uploaded_data => stub_file_data('file1.txt', nil, 'text/html'), :content_type => 'text/html')
      att2 = attachment_model(:uploaded_data => stub_file_data('file2.txt', nil, 'text/html'), :content_type => 'text/html')
      att3 = attachment_model(:uploaded_data => stub_file_data('file3.txt', nil, 'text/html'), :content_type => 'text/html')
      [att1, att2, att3].each {|att| att.need_notify.should be_true}

      new_time = Time.now + 2.minutes
      Time.stubs(:now).returns(new_time)
      Attachment.do_notifications
      [att1, att2, att3].each {|att| att.reload.need_notify.should be_true}
      Message.find_by_user_id_and_notification_name(@student.id, 'New Files Added').should be_nil

      new_time = Time.now + 4.minutes
      Time.stubs(:now).returns(new_time)
      Attachment.do_notifications
      [att1, att2, att3].each {|att| att.reload.need_notify.should_not be_true}
      Message.find_by_user_id_and_notification_name(@student.id, 'New Files Added').should_not be_nil
    end

    it "should discard really old pending notifications" do
      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')
      @attachment.need_notify.should be_true

      new_time = Time.now + 1.week
      Time.stubs(:now).returns(new_time)
      Attachment.do_notifications

      @attachment.reload
      @attachment.need_notify.should be_false
      Message.find_by_user_id_and_notification_name(@student.id, 'New Files Added').should be_nil
      Message.find_by_user_id_and_notification_name(@student.id, 'New File Added').should be_nil
    end

    it "should respect save_without_broadcasting" do
      att1 = attachment_model(:file_state => 'deleted', :uploaded_data => stub_file_data('file1.txt', nil, 'text/html'), :content_type => 'text/html')
      att2 = attachment_model(:file_state => 'deleted', :uploaded_data => stub_file_data('file2.txt', nil, 'text/html'), :content_type => 'text/html')
      att3 = attachment_model(:file_state => 'deleted', :uploaded_data => stub_file_data('file2.txt', nil, 'text/html'), :content_type => 'text/html')

      att1.need_notify.should_not be_true
      att1.file_state = 'available'
      att1.save!
      att1.need_notify.should be_true

      att2.need_notify.should_not be_true
      att2.file_state = 'available'
      att2.save_without_broadcasting
      att2.need_notify.should_not be_true

      att3.need_notify.should_not be_true
      att3.file_state = 'available'
      att3.save_without_broadcasting!
      att3.need_notify.should_not be_true
    end

    it "should not send notifications to students if the file is uploaded to a locked folder" do
      @teacher.register!
      cc = @teacher.communication_channels.create!(:path => "default@example.com")
      cc.confirm!
      NotificationPolicy.create!(:notification => Notification.find_by_name('New File Added'), :communication_channel => cc, :frequency => "immediately")

      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')

      @attachment.folder.locked = true
      @attachment.folder.save!

      new_time = Time.now + 10.minutes
      Time.stubs(:now).returns(new_time)
      Attachment.do_notifications

      @attachment.reload
      @attachment.need_notify.should_not be_true
      Message.find_by_user_id_and_notification_name(@student.id, 'New File Added').should be_nil
      Message.find_by_user_id_and_notification_name(@teacher.id, 'New File Added').should_not be_nil
    end

    it "should not send notifications to students if the files navigation is hidden from student view" do
      @teacher.register!
      cc = @teacher.communication_channels.create!(:path => "default@example.com")
      cc.confirm!
      NotificationPolicy.create!(:notification => Notification.find_by_name('New File Added'), :communication_channel => cc, :frequency => "immediately")

      attachment_model(:uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')

      @course.tab_configuration = [{:id => Course::TAB_FILES, :hidden => true}]
      @course.save!

      new_time = Time.now + 10.minutes
      Time.stubs(:now).returns(new_time)
      Attachment.do_notifications

      @attachment.reload
      @attachment.need_notify.should_not be_true
      Message.find_by_user_id_and_notification_name(@student.id, 'New File Added').should be_nil
      Message.find_by_user_id_and_notification_name(@teacher.id, 'New File Added').should_not be_nil
    end

    it "should not fail if the attachment context does not have participants" do
      cm = ContentMigration.create!(:context => course)
      attachment_model(:context => cm, :uploaded_data => stub_file_data('file.txt', nil, 'text/html'), :content_type => 'text/html')

      Attachment.where(:id => @attachment).update_all(:need_notify => true)

      new_time = Time.now + 10.minutes
      Time.stubs(:now).returns(new_time)
      Attachment.do_notifications
    end
  end

  context "quota" do
    it "should give small files a minimum quota size" do
      course_model
      attachment_model(:context => @course, :uploaded_data => stub_png_data, :size => 25)
      quota = Attachment.get_quota(@course)
      quota[:quota_used].should == Attachment.minimum_size_for_quota
    end
  end

  context "#open" do
    context "s3_storage" do
      before do
        s3_storage!
        attachment_model
        @attachment.s3object.class.any_instance.expects(:read).yields("test")
      end

      it "should stream data to the block given" do
        callback = false
        @attachment.open { |data| data.should == "test"; callback = true }
        callback.should == true
      end

      it "should stream to a tempfile without a block given" do
        file = @attachment.open
        file.should be_a(Tempfile)
        file.read.should == "test"
      end
    end
  end

  context "#process_s3_details!" do
    before do
      Attachment.stubs(:local_storage?).returns(false)
      Attachment.stubs(:s3_storage?).returns(true)
      attachment_model(filename: 'new filename', cached_scribd_thumbnail: "THUMBNAIL_URL")
      @attachment.stubs(:s3object).returns(mock('s3object'))
      @attachment.stubs(:after_attachment_saved)
    end

    context "deduplication" do
      before do
        attachment = @attachment
        @existing_attachment = attachment_model(filename: 'existing filename', cached_scribd_thumbnail: "THUMBNAIL_URL")
        @child_attachment = attachment_model(root_attachment: @existing_attachment, cached_scribd_thumbnail: "THUMBNAIL_URL")
        @attachment = attachment

        @existing_attachment.stubs(:s3object).returns(mock('existing_s3object'))
        @attachment.stubs(:find_existing_attachment_for_md5).returns(@existing_attachment)
      end

      context "existing attachment has s3object" do
        before do
          @existing_attachment.s3object.stubs(:exists?).returns(true)
          @attachment.s3object.stubs(:delete)
        end

        it "should delete the new (redundant) s3object" do
          @attachment.s3object.expects(:delete).once
          @attachment.process_s3_details!({})
        end

        it "should put the new attachment under the existing attachment" do
          @attachment.process_s3_details!({})
          @attachment.reload.root_attachment.should == @existing_attachment
        end

        it "should retire the new attachment's filename" do
          @attachment.process_s3_details!({})
          @attachment.reload.filename.should == @existing_attachment.filename
        end

        it "should retire the new attachment's cached_scribd_thumbnail" do
          @attachment.process_s3_details!({})
          @attachment.reload.cached_scribd_thumbnail.should be_nil
        end
      end

      context "existing attachment is missing s3object" do
        before do
          @existing_attachment.s3object.stubs(:exists?).returns(false)
        end

        it "should not delete the new s3object" do
          @attachment.s3object.expects(:delete).never
          @attachment.process_s3_details!({})
        end

        it "should not put the new attachment under the existing attachment" do
          @attachment.process_s3_details!({})
          @attachment.reload.root_attachment.should be_nil
        end

        it "should not retire the new attachment's filename" do
          @attachment.process_s3_details!({})
          @attachment.reload.filename == 'new filename'
        end

        it "should not retire the new attachment's cached_scribd_thumbnail" do
          @attachment.process_s3_details!({})
          @attachment.reload.cached_scribd_thumbnail == 'scribd url'
        end

        it "should put the existing attachment under the new attachment" do
          @attachment.process_s3_details!({})
          @existing_attachment.reload.root_attachment.should == @attachment
        end

        it "should retire the existing attachment's filename" do
          @attachment.process_s3_details!({})
          @existing_attachment.reload.read_attribute(:filename).should be_nil
          @existing_attachment.filename.should == @attachment.filename
        end

        it "should retire the existing attachment's cached_scribd_thumbnail" do
          @attachment.process_s3_details!({})
          @existing_attachment.reload.cached_scribd_thumbnail.should be_nil
        end

        it "should reparent the child attachment under the new attachment" do
          @attachment.process_s3_details!({})
          @child_attachment.reload.root_attachment.should == @attachment
        end

        it "should retire the child attachment's cached_scribd_thumbnail" do
          @attachment.process_s3_details!({})
          @child_attachment.reload.cached_scribd_thumbnail.should be_nil
        end
      end
    end
  end

  describe ".delete_stale_scribd_docs" do
    before do
      attachment_model
      @attachment.scribd_doc = Scribd::Document.new
      ScribdAPI.stubs(:enabled?).returns(true)
    end

    it "should delete old views ones" do
      Scribd::Document.any_instance.expects(:destroy).returns(true).once
      @attachment.update_attribute(:last_inline_view, 1.year.ago)
      Attachment.delete_stale_scribd_docs
      @attachment.reload
      @attachment.scribd_doc.should be_nil
      @attachment.workflow_state.should == 'deleted'
    end

    it "should delete old ones that were never viewed" do
      Scribd::Document.any_instance.expects(:destroy).returns(true).once
      @attachment.update_attribute(:created_at, 1.year.ago)
      Attachment.delete_stale_scribd_docs
      @attachment.reload
      @attachment.scribd_doc.should be_nil
      @attachment.workflow_state.should == 'deleted'
    end

    it "should not delete new ones that were never viewed" do
      Scribd::Document.any_instance.expects(:destroy).never
      @attachment.save!
      Attachment.delete_stale_scribd_docs
      @attachment.reload
      @attachment.scribd_doc.should_not be_nil
    end

    it "should not delete recently viewed ones" do
      Scribd::Document.any_instance.expects(:destroy).never
      @attachment.update_attribute(:last_inline_view, 1.hour.ago)
      Attachment.delete_stale_scribd_docs
      @attachment.reload
      @attachment.scribd_doc.should_not be_nil
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
        @attachment.grants_right?(@s1, :attach_to_submission_comment).should be_true
        @attachment.grants_right?(@s2, :attach_to_submission_comment).should be_false
      end
    end
  end

  describe "#full_path" do
    it "shouldn't puke for things that don't have folders" do
      attachment_obj_with_context(Account.default.default_enrollment_term)
      @attachment.folder = nil
      @attachment.full_path.should == "/#{@attachment.display_name}"
    end
  end

  describe '.context_type' do
    it 'returns the correct representation of a quiz statistics relation' do
      stats = Quizzes::QuizStatistics.create!(report_type: 'student_analysis')
      attachment = attachment_obj_with_context(Account.default.default_enrollment_term)
      attachment.context = stats
      attachment.save
      attachment.context_type.should == "Quizzes::QuizStatistics"

      Attachment.where(id: attachment).update_all(context_type: 'QuizStatistics')

      Attachment.find(attachment.id).context_type.should == 'Quizzes::QuizStatistics'
    end
  end

end

def processing_model
  document = Scribd::Document.new
  Scribd::API.instance.stubs(:user=).returns(true)
  document.stubs(:conversion_status).returns(:status_from_scribd)
  ScribdAPI.stubs(:upload).returns(document)
  scribdable_attachment_model
  @attachment.submit_to_scribd!
end

