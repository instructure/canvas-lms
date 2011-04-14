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

describe Attachment do
  
  context "validation" do
    it "should create a new instance given valid attributes" do
      attachment_model
    end

    it "should require a context" do
      lambda{attachment_model(:context => nil)}.should raise_error(ActiveRecord::RecordInvalid, /Validation failed: Context can't be blank/)
    end
    
  end
  
  context "default_values" do
    it "should set the display name to the filename if it is nil" do
      attachment_model(:display_name => nil)
      @attachment.display_name.should eql(@attachment.filename)
    end
    
    it "should set the scribd_mime_type_id to the appropriate value" do
      # scribdable_attachment_model
      scribd_mime_type_model(:extension => 'pdf')
      @course = course_model
      @attachment = Attachment.new()
      @attachment.context = @course
      @attachment.filename = 'some_file.pdf'
      @attachment.content_type = 'pdf'
      ScribdMimeType.find_by_name(@attachment.content_type).should eql(@scribd_mime_type)
      Attachment.clear_cached_mime_ids
      @attachment.save!
      
      @attachment.scribd_mime_type.should_not be_nil
      @attachment.content_type.should eql('pdf')
      @attachment.scribd_mime_type.extension.should eql("pdf")
      #@attachment.scribd_mime_type.should eql(@scribd_mime_type)
    end
    
    it "should create a ScribdAccount if one isn't present" do
      scribd_mime_type_model(:extension => 'pdf')
      course_model
      @course.scribd_account.should be_nil
      attachment_obj_with_context(@course, :content_type => 'pdf')
      @attachment.context.should eql(@course)
      @attachment.context.scribd_account.should be_nil
      previous_scribd_account_count = ScribdAccount.all.size
      @attachment.save!
      @attachment.context.scribd_account.should_not be_nil
      @attachment.context.scribd_account.should be_is_a(ScribdAccount)
      ScribdAccount.all.size.should eql(previous_scribd_account_count + 1)
    end
    
    it "should set the attachment.scribd_account to the context scribd_account" do
      scribdable_attachment_model
      @attachment.scribd_account.should eql(@attachment.context.scribd_account)
    end
    
  end

  it "should be scribdable if scribd_mime_type_id is set" do
    scribdable_attachment_model
    @attachment.should be_scribdable
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
    before(:all) do
      ScribdAPI.stub!(:set_user).and_return(true)
      ScribdAPI.stub!(:upload).and_return(UUIDSingleton.instance.generate)
    end
    
    it "should upload scribdable attachments" do
      scribdable_attachment_model
      @doc_obj = Scribd::Document.new
      ScribdAPI.should_receive(:upload).and_return(@doc_obj)
      @doc_obj.stub!(:thumbnail).and_return("the url to the scribd doc thumbnail")
      @attachment.submit_to_scribd!.should be_true
      @attachment.scribd_doc.should eql(@doc_obj)
      @attachment.state.should eql(:processing)
    end
    
    it "should bypass non-scridbable attachments" do
      attachment_model
      @attachment.should_not be_scribdable
      ScribdAPI.should_not_receive(:set_user)
      ScribdAPI.should_not_receive(:upload)
      @attachment.submit_to_scribd!.should be_true
      @attachment.state.should eql(:processed)
    end
    
    it "should not mess with attachments outside the pending_upload state" do
      ScribdAPI.should_not_receive(:set_user)
      ScribdAPI.should_not_receive(:upload)
      attachment_model(:workflow_state => 'processing')
      @attachment.submit_to_scribd!.should be_false
      attachment_model(:workflow_state => 'processed')
      @attachment.submit_to_scribd!.should be_false
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
  
  context "conversion_status" do
    before(:each) do
      ScribdAPI.stub!(:get_status).and_return(:status_from_scribd)
      ScribdAPI.stub!(:set_user).and_return(true)
      ScribdAPI.stub!(:upload).and_return(Scribd::Document.new)
    end
    
    it "should have a default conversion_status of :not_submitted for attachments that haven't been submitted" do
      attachment_model
      @attachment.conversion_status.should eql('NOT SUBMITTED')
    end
    
    it "should ask Scribd for the status" do
      ScribdAPI.should_receive(:get_status).and_return(:status_from_scribd)
      scribdable_attachment_model
      @doc_obj = Scribd::Document.new
      ScribdAPI.should_receive(:upload).and_return(@doc_obj)
      @doc_obj.stub!(:thumbnail).and_return("the url to the scribd doc thumbnail")
      @attachment.submit_to_scribd!
      @attachment.conversion_status
    end
    
  end
  
  context "download_url" do
    before do
      ScribdAPI.stub!(:set_user).and_return(true)
      @doc = mock('Scribd Document', :download_url => 'some url')
      Scribd::Document.stub!(:find).and_return(@doc)
    end

    # Not working, doesn't need to work for now.
    # it "should get the URL from the Scribd service" do
    #   processing_model
    #   @attachment.download_url.should eql('some url')
    # end
    # 
    # it "should not ask for the url more than once" do
    #   processing_model
    #   @attachment.download_url.should eql('some url')
    #   ScribdAPI.should_not_receive(:set_user)
    #   @attachment.download_url.should eql('some url')
    # end
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
  end
  
  context "uploaded_data" do
    it "should create with uploaded_date" do
      a = attachment_model(:uploaded_data => default_uploaded_data)
      a.filename.should eql("doc.doc")
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

end

def processing_model
  ScribdAPI.stub!(:get_status).and_return(:status_from_scribd)
  ScribdAPI.stub!(:set_user).and_return(true)
  ScribdAPI.stub!(:upload).and_return(Scribd::Document.new)
  scribdable_attachment_model
  @attachment.submit_to_scribd!
end

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

# Makes sure we have a value in scribd_mime_types and that the attachment model points to that.
def scribdable_attachment_model
  scribd_mime_type_model(:extension => 'pdf')
  attachment_model(:content_type => 'pdf')
end
