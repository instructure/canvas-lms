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

describe SIS::SisCsv do
  before do
    account_model
  end
  
  def process_csv_data(*lines)
    tmp = Tempfile.new("sis_rspec")
    path = "#{tmp.path}.csv"
    tmp.close!
    File.open(path, "w+") { |f| f.puts lines.join "\n" }
    
    importer = SIS::SisCsv.process(@account, :files => [ path ], :allow_printing=>false)
    
    File.unlink path
    
    importer
  end
  
  it "should error files with unknown headers" do
    importer = process_csv_data(
      "course_id,randomness,smelly",
      "test_1,TC 101,Test Course 101,,,active"
    )
    importer.errors.first.last.should == "Couldn't find Canvas CSV import headers"
  end
  
  context "course importing" do
    it 'should detect bad content' do
      before_count = Course.count
      importer = process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,Hum101,Humanities,A001,T001,active",
        "C001,Hum102,Humanities 2,A001,T001,active",
        ",Hum102,Humanities 2,A001,T001,active",
        "C003,Hum102,Humanities 2,A001,T001,inactive",
        "C004,,Humanities 2,A001,T001,active",
        "C005,Hum102,,A001,T001,active"
      )
      Course.count.should == before_count

      errors = importer.errors.map { |r| r.last }
      errors.should == ["Duplicate course id C001",
                        "No course_id given for a course",
                        "Improper status \"inactive\" for course C003",
                        "No short_name given for course C004",
                        "No long_name given for course C005"]
    end
    
    it "should create new courses" do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("TC 101")
      course.name.should eql("Test Course 101")
    end
    
    it "should rename courses that have not had their name manually changed" do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active",
        "test_2,TB 101,Testing & Breaking 101,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("TC 101")
      course.name.should eql("Test Course 101")
      
      course = @account.courses.find_by_sis_source_id("test_2")
      course.name.should eql("Testing & Breaking 101")
      
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 102,Test Course 102,,,active",
        "test_2,TB 102,Testing & Breaking 102,,,active"
      )
      
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("TC 102")
      course.name.should eql("Test Course 102")
      
      course = @account.courses.find_by_sis_source_id("test_2")
      course.name.should eql("Testing & Breaking 102")
    end
    
    it "should not rename courses that have had their names manually changed" do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("TC 101")
      course.name.should eql("Test Course 101")
      
      course.name = "Haha my course lol"
      course.course_code = "SUCKERS 101"
      course.save
      
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 102,Test Course 102,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("SUCKERS 101")
      course.name.should eql("Haha my course lol")
    end
  end
  
  context "user importing" do
    it "should create new users and update names" do
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.account.should eql(@account)
      user.name.should eql("User Uno")
      
      user.pseudonyms.count.should eql(1)
      pseudonym = user.pseudonyms.first
      pseudonym.unique_id.should eql('user1')
      
      user.communication_channels.count.should eql(1)
      cc = user.communication_channels.first
      cc.path.should eql("user@example.com")
      
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno 2,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.account.should eql(@account)
      user.name.should eql("User Uno 2")
      
      user.pseudonyms.count.should eql(1)
      pseudonym = user.pseudonyms.first
      pseudonym.unique_id.should eql('user1')
      
      user.communication_channels.count.should eql(1)
      
      user.name = "My Awesome Name"
      user.save
      
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno 2,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.account.should eql(@account)
      user.name.should eql("My Awesome Name")
    end
    
    it "should set passwords and not overwrite current passwords" do
      process_csv_data(
        "user_id,login_id,password,first_name,last_name,email,status",
        "user_1,user1,badpassword,User,Uno 2,user@example.com,active"     
      )
      user = User.find_by_email('user@example.com')
      p = user.pseudonyms.first
      p.valid_password?('badpassword').should be_true
      
      p.password = 'lessbadpassword'
      p.password_confirmation = 'lessbadpassword'
      p.save
      
      process_csv_data(
        "user_id,login_id,password,first_name,last_name,email,status",
        "user_1,user1,badpassword2,User,Uno 2,user@example.com,active"     
      )
      
      user.reload
      p = user.pseudonyms.first
      p.valid_password?('badpassword').should be_false
      p.valid_password?('badpassword2').should be_false
      p.valid_password?('lessbadpassword').should be_true
    end
    
    it "should warn for duplicate rows" do
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.should_not be_nil
      
      warnings = importer.warnings.map { |r| r.last }
      warnings.should == ['Duplicate user id user_1']
    end
    
    it "should not allow non-identical duplicate user rows" do
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active",
        "user_1,user2,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.should be_nil
      
      errors = importer.errors.map { |r| r.last }
      errors.should == ['Non-identical duplicate user rows for user_1']
    end

    it "should not allow non-identical duplicate user rows in multiple files" do
      file1 = ["user_id,login_id,first_name,last_name,email,status",
              "user_1,user1,User,Uno,user@example.com,active"]
      file2 = ["user_id,login_id,first_name,last_name,email,status",
              "user_1,user2,User,Uno,user@example.com,active"]
      tmp = Tempfile.new("sis_rspec")
      path = "#{tmp.path}.csv"
      tmp.close!
      File.open(path, "w+") { |f| f.puts file1.join "\n" }
      tmp2 = Tempfile.new("sis_rspec2")
      path2 = "#{tmp2.path}.csv"
      tmp2.close!
      File.open(path2, "w+") { |f| f.puts file2.join "\n" }
      
      importer = SIS::SisCsv.process(@account, :files => [path,path2], :allow_printing=>false)

      File.unlink path
      File.unlink path2

      user = User.find_by_email('user@example.com')
      user.should be_nil

      errors = importer.errors.map { |r| r.last }
      errors.should == ['Non-identical duplicate user rows for user_1']
    end
    
    it "should not allow a secondary user account with the same login id." do
      p_count = Pseudonym.count
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.pseudonyms.count.should == 1
      user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_1'
      
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_2,user1,User,Uno,user@example.com,active"
      )
      importer.warnings.map{|r|r.last}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
      user = User.find_by_email('user@example.com')
      user.pseudonyms.count.should == 1
      user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_1'
      Pseudonym.count.should == (p_count + 1)
    end
    
    it "should not allow a secondary user account to change its login id to some other registered login id" do
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active"
      )
      
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_2,user1,User,Dos,user2@example.com,active",
        "user_1,user3,User,Uno,user1@example.com,active"
      )
      importer.warnings.map{|r|r.last}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").unique_id.should == "user3"
      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_2").unique_id.should == "user2"
    end
    
    it "should allow a secondary user account to change its login id to some other registered login id if the other changes it first" do
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active"
      )
     
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user3,User,Uno,user1@example.com,active",
        "user_2,user1,User,Dos,user2@example.com,active"
      )
      importer.warnings.should == []
      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").unique_id.should == "user3"
      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_2").unique_id.should == "user1"
    end
    
    it "should allow a user to update information" do
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )
      importer.warnings.should == []
      importer.errors.should == []
     
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user2,User,Uno-Dos,user1@example.com,active"
      )
      importer.warnings.should == []
      importer.errors.should == []

      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.last_name.should == "Uno-Dos"
    end
    
    it "should add two users with different user_ids, login_ids, but the same email" do
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active",
        "user_2,user2,User,Dos,user@example.com,active"
      )
      importer.errors.should == []
      importer.warnings.should == []
      user1 = Pseudonym.find_by_unique_id('user1').user
      user2 = Pseudonym.find_by_unique_id('user2').user
      user1.should_not == user2
      user1.last_name.should == "Uno"
      user2.last_name.should == "Dos"
      user1.pseudonyms.count.should == 1
      user2.pseudonyms.count.should == 1
      user1.pseudonyms.first.communication_channel_id.should_not be_nil
      user2.pseudonyms.first.communication_channel_id.should be_nil
    end
    
    it "should not add a user with the same login id as another user" do
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user1,User,Dos,user2@example.com,active"
      )
      importer.errors.should == []
      importer.warnings.map{|x| x[1]}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
      Pseudonym.find_by_unique_id('user1').should_not be_nil
      Pseudonym.find_by_unique_id('user2').should be_nil
    end
    
    it "should use an existing pseudonym if it wasn't imported from sis and has the same login id" do
      u = User.create!
      u.register!
      p_count = Pseudonym.count
      p = u.pseudonyms.create!(:unique_id => "user2", :path => "user2", :password => "validpassword", :password_confirmation => "validpassword", :account => @account)
      Pseudonym.find_by_unique_id('user1').should be_nil
      Pseudonym.find_by_unique_id('user2').should_not be_nil
      p.sis_user_id.should be_nil
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active"
      )
      p.reload
      importer.errors.should == []
      importer.warnings.should == []
      Pseudonym.find_by_unique_id('user1').should_not be_nil
      Pseudonym.find_by_unique_id('user2').should_not be_nil
      Pseudonym.count.should == (p_count + 2)
      p.sis_user_id.should == "user_2"
    end
    
    it "should use an existing pseudonym if it wasn't imported from sis and has the same email address" do
      u = User.create!
      u.register!
      p_count = Pseudonym.count
      p = u.pseudonyms.create!(:unique_id => "user2@example.com", :path => "user2@example.com", :password => "validpassword", :password_confirmation => "validpassword", :account => @account)
      Pseudonym.find_by_unique_id('user1').should be_nil
      Pseudonym.find_by_unique_id('user2').should be_nil
      Pseudonym.find_by_unique_id('user2@example.com').should_not be_nil
      p.sis_user_id.should be_nil
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active"
      )
      p.reload
      importer.errors.should == []
      importer.warnings.should == []
      Pseudonym.find_by_unique_id('user1').should_not be_nil
      Pseudonym.find_by_unique_id('user2').should_not be_nil
      Pseudonym.find_by_unique_id('user2@example.com').should be_nil
      Pseudonym.count.should == (p_count + 2)
      p.sis_user_id.should == "user_2"
    end
    
  end
  
  context 'enrollment importing' do
    it 'should detect bad content' do
      before_count = Enrollment.count
      importer = process_csv_data(
        "course_id,user_id,role,section_id,status",
        ",U001,student,,active",
        "C001,,student,1B,active",
        "C001,U001,cheater,1B,active",
        "C001,U001,student,1B,semi-active"
      )
      Enrollment.count.should == before_count

      errors = importer.errors.map { |r| r.last }
      errors.should == ["No course_id or section_id given for an enrollment",
                        "No user_id given for an enrollment",
                        "Improper role \"cheater\" for an enrollment",
                        "Improper status \"semi-active\" for an enrollment"]
    end

    it 'should warn about inconsistent data' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active",
        "C002,TC 102,Test Course 102,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "1B,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "U001,user1,User,Uno,user@example.com,active"
      )
      importer = process_csv_data(
        "course_id,user_id,role,section_id,status",
        "NONEXISTENT,U001,student,1B,active",
        "C001,U001,student,NONEXISTENT,active",
        "C002,U001,student,1B,active")
      warnings = importer.warnings.map { |r| r.last }
      warnings.should == ["An enrollment referenced a non-existent course NONEXISTENT",
                          "An enrollment referenced a non-existent section NONEXISTENT",
                          "An enrollment listed a section and a course that are unrelated"]
    end

    it "should enroll users" do
      #create course, users, and sections
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active",
        "user_3,user4,User,Tres,user3@example.com,active",
        "user_5,user5,User,Quatro,user5@example.com,active",
        "user_6,user6,User,Cinco,user6@example.com,active"
      )
      process_csv_data(
        "section_id,course_id,name,status,start_date,end_date",
        "S001,test_1,Sec1,active,,"
      )
      # the enrollments
      process_csv_data(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "test_1,user_1,teacher,,active,",
        ",user_2,student,S001,active,",
        "test_1,user_3,ta,S001,active,",
        "test_1,user_5,observer,S001,active,user_2",
        "test_1,user_6,designer,S001,active,"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.teachers.first.name.should == "User Uno"
      course.students.first.name.should == "User Dos"
      course.tas.first.name.should == "User Tres"
      course.observers.first.name.should == "User Quatro"
      course.observer_enrollments.first.associated_user_id.should == course.students.first.id
      course.designers.first.name.should == "User Cinco"
    end

    it "should not try looking up a section to enroll into if the section name is empty" do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active",
        "test_2,TC 102,Test Course 102,,,active"
      )
      bad_course = @account.courses.find_by_sis_source_id("test_1")
      bad_course.course_sections.length.should == 1
      good_course = @account.courses.find_by_sis_source_id("test_2")
      good_course.course_sections.length.should == 1
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      importer = process_csv_data(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "test_2,user_1,teacher,,active,"
      )
      importer.warnings.length.should == 0
      importer.errors.length.should == 0
      good_course.teachers.first.name.should == "User Uno"
    end
  end

  context 'account importing' do
    it 'should detect bad content' do
      before_count = Account.count
      importer = process_csv_data(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A001,,Humanities 2,active",
        ",,Humanities 3,active")

      errors = importer.errors.map { |r| r.last }
      warnings = importer.warnings.map { |r| r.last }
      errors.should == ["Duplicate account id A001",
                        "No account_id given for an account"]
      warnings.should == []

      importer = process_csv_data(
        "account_id,parent_account_id,name,status",
        "A002,A001,English,active",
        "A003,,English,inactive",
        "A004,,,active")
      Account.count.should == before_count

      errors = importer.errors.map { |r| r.last }
      warnings = importer.warnings.map { |r| r.last }
      errors.should == []
      warnings.should == ["Parent account didn't exist for A002",
                          "Improper status \"inactive\" for account A003, skipping",
                          "No name given for account A004, skipping"]
    end
    
    it 'should create accounts' do
      before_count = Account.count
      process_csv_data(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A002,A001,English,active",
        "A003,A002,English Literature,active",
        "A004,,Awesomeness,active"
      )
      Account.count.should == before_count + 4
      
      a1 = @account.sub_accounts.find_by_sis_source_id('A001')
      a1.should_not be_nil
      a1.parent_account_id.should == @account.id
      a1.root_account_id.should == @account.id
      a1.name.should == 'Humanities'
      
      a2 = a1.sub_accounts.find_by_sis_source_id('A002')
      a2.should_not be_nil
      a2.parent_account_id.should == a1.id
      a2.root_account_id.should == @account.id
      a2.name.should == 'English'
      
      a3 = a2.sub_accounts.find_by_sis_source_id('A003')
      a3.should_not be_nil
      a3.parent_account_id.should == a2.id
      a3.root_account_id.should == @account.id
      a3.name.should == 'English Literature'
    end

    it 'should update the hierarchies of existing accounts' do
      before_count = Account.count
      importer = process_csv_data(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A002,,English,deleted",
        "A003,,English Literature,active",
        "A004,,Awesomeness,active"
      )
      importer.warnings.should == []
      importer.errors.should == []
      Account.count.should == before_count + 4
      
      ['A001', 'A002', 'A003', 'A004'].each do |id|
        Account.find_by_sis_source_id(id).parent_account.should == @account
      end
      Account.find_by_sis_source_id('A002').workflow_state.should == "deleted"
      Account.find_by_sis_source_id('A003').name.should == "English Literature"

      importer = process_csv_data(
        "account_id,parent_account_id,name,status",
        "A002,A001,,",
        "A003,A002,,",
        "A004,A002,,"
      )
      importer.warnings.should == []
      importer.errors.should == []
      Account.count.should == before_count + 4

      a1 = Account.find_by_sis_source_id('A001')
      a2 = Account.find_by_sis_source_id('A002')
      a3 = Account.find_by_sis_source_id('A003')
      a4 = Account.find_by_sis_source_id('A004')
      a1.parent_account.should == @account
      a2.parent_account.should == a1
      a3.parent_account.should == a2
      a4.parent_account.should == a2

      Account.find_by_sis_source_id('A002').workflow_state.should == "deleted"
      Account.find_by_sis_source_id('A003').name.should == "English Literature"
      
    end
  end
  
  context 'term importing' do
    it 'should detect bad content' do
      before_count = EnrollmentTerm.count
      importer = process_csv_data(
        "term_id,name,status,start_date,end_date",
        "T001,Winter11,active,,",
        "T001,Winter12,active,,",
        ",Winter13,active,,",
        "T002,Winter10,inactive,,",
        "T003,,active,,"
      )
      EnrollmentTerm.count.should == before_count

      errors = importer.errors.map { |r| r.last }
      errors.should == ["Duplicate term id T001",
                        "No term_id given for a term",
                        "Improper status \"inactive\" for term T002",
                        "No name given for term T003"]
    end
    
    it 'should create terms' do
      before_count = EnrollmentTerm.count
      importer = process_csv_data(
        "term_id,name,status,start_date,end_date",
        "T001,Winter11,active,2011-1-05 00:00:00,2011-4-14 00:00:00",
        "T002,Winter12,active,2012-13-05 00:00:00,2012-14-14 00:00:00",
        "T003,Winter13,active,,"
      )
      EnrollmentTerm.count.should == before_count + 3
      
      t1 = @account.enrollment_terms.find_by_sis_source_id('T001')
      t1.should_not be_nil
      t1.name.should == 'Winter11'
      t1.start_at.to_s(:db).should == '2011-01-05 00:00:00'
      t1.end_at.to_s(:db).should == '2011-04-14 00:00:00'
      
      t2 = @account.enrollment_terms.find_by_sis_source_id('T002')
      t2.should_not be_nil
      t2.name.should == 'Winter12'
      t2.start_at.should be_nil
      t2.end_at.should be_nil
      
      importer.warnings.map{|r|r.last}.should == ["Bad date format for term T002"]
    end
  end
  
  context 'section importing' do
    it 'should detect bad content' do
      before_count = CourseSection.count
      importer = process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,,,active",
        "S001,C001,Sec2,,,active",
        "S002,,Sec2,,,active",
        ",C001,Sec2,,,active",
        "S003,C002,Sec1,,,inactive",
        "S004,C002,,,,active"
      )
      CourseSection.count.should == before_count

      errors = importer.errors.map { |r| r.last }
      errors.should == ["Duplicate section id S001",
                        "No course_id given for a section S002",
                        "No section_id given for a section in course C001",
                        "Improper status \"inactive\" for section S003 in course C002",
                        "No name given for section S004 in course C002"]
    end
    
    it 'should create sections' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active"
      )
      before_count = CourseSection.count
      importer = process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
        "S002,C001,Sec2,2012-13-05 00:00:00,2012-14-14 00:00:00,active",
        "S003,C002,Sec1,,,active"
      )
      CourseSection.count.should == before_count + 2
      
      course = @account.courses.find_by_sis_source_id("C001")
      
      s1 = course.course_sections.find_by_sis_source_id('S001')
      s1.should_not be_nil
      s1.name.should == 'Sec1'
      s1.start_at.to_s(:db).should == '2011-01-05 00:00:00'
      s1.end_at.to_s(:db).should == '2011-04-14 00:00:00'
      
      s2 = course.course_sections.find_by_sis_source_id('S002')
      s2.should_not be_nil
      s2.name.should == 'Sec2'
      s2.start_at.should be_nil
      s2.end_at.should be_nil
      
      importer.warnings.map{|r|r.last}.should == ["Bad date format for section S002",
                                                  "Section S003 references course C002 which doesn't exist"]
    end
    
    it 'should verify xlist files' do
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        ",S001,active"
      )
      importer.warnings.should == []
      importer.errors.map{|r|r.last}.should == ["No xlist_course_id given for a cross-listing"]
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,,active"
      )
      importer.warnings.should == []
      importer.errors.map{|r|r.last}.should == ["No section_id given for a cross-listing"]
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,"
      )
      importer.warnings.should == []
      importer.errors.map{|r|r.last}.should == ['Improper status "" for a cross-listing']
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,baleeted"
      )
      importer.warnings.should == []
      importer.errors.map{|r|r.last}.should == ['Improper status "baleeted" for a cross-listing']
      @account.courses.size.should == 0
    end
    
    it 'should work with xlists with no xlist course' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
        "S002,C001,Sec2,2012-12-05 00:00:00,2012-12-14 00:00:00,active"
      )
      
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil
      @account.courses.find_by_sis_source_id("X001").should be_nil
      
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      
      importer.warnings.should == []
      importer.errors.should == []
      
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.account.should eql(course.account)
      course.course_sections.find_by_sis_source_id("S001").should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil
      
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,deleted"
      )
      
      importer.warnings.should == []
      importer.errors.should == []
      
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      xlist_course.course_sections.find_by_sis_source_id("S001").should be_nil
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil

      xlist_course.name.should == "Test Course 101"
      xlist_course.sis_name.should == "Test Course 101"
      xlist_course.short_name.should == "TC 101"
      xlist_course.sis_course_code.should == "TC 101"
      xlist_course.sis_source_id.should == "X001"
      xlist_course.root_account_id.should == @account.id
      xlist_course.account_id.should == @account.id
      xlist_course.workflow_state.should == "claimed"
    end
      
    it 'should work with xlists with an xlist course defined' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "X001,TC 102,Test Course 102,,,active",
        "C001,TC 101,Test Course 101,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
        "S002,C001,Sec2,2012-12-05 00:00:00,2012-12-14 00:00:00,active"
      )
      
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil
      @account.courses.find_by_sis_source_id("X001").should_not be_nil
      
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      
      importer.warnings.should == []
      importer.errors.should == []
      
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.account.should eql(course.account)
      course.course_sections.find_by_sis_source_id("S001").should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil
      
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,deleted"
      )
      
      importer.warnings.should == []
      importer.errors.should == []
      
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      xlist_course.course_sections.find_by_sis_source_id("S001").should be_nil
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil

      xlist_course.name.should == "Test Course 102"
    end
      
    it 'should work with xlist courses in crazy orders' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
        "S002,C001,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
        "S003,C001,Sec3,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
        "S004,C001,Sec4,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
        "S005,C001,Sec5,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,active",
        "X001,S002,active",
        "X001,S003,active",
        "X002,S004,active",
        "X001,S005,active"
      )
      
      importer.warnings.should == []
      importer.errors.should == []
      
      xlist_course_1 = @account.courses.find_by_sis_source_id("X001")
      xlist_course_2 = @account.courses.find_by_sis_source_id("X002")
      xlist_course_1.course_sections.find_by_sis_source_id("S001").should_not be_nil
      xlist_course_1.course_sections.find_by_sis_source_id("S002").should_not be_nil
      xlist_course_1.course_sections.find_by_sis_source_id("S003").should_not be_nil
      xlist_course_2.course_sections.find_by_sis_source_id("S004").should_not be_nil
      xlist_course_1.course_sections.find_by_sis_source_id("S005").should_not be_nil
    end
      
    it 'should be idempotent with active xlists' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      3.times do 
        importer = process_csv_data(
          "xlist_course_id,section_id,status",
          "X001,S001,active"
        )
        importer.warnings.should == []
        importer.errors.should == []
        
        xlist_course = @account.courses.find_by_sis_source_id("X001")
        course = @account.courses.find_by_sis_source_id("C001")
        s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
        s1.should_not be_nil
        s1.nonxlist_course.should eql(course)
        s1.account.should eql(course.account)
      end
    end

    it 'should be idempotent with deleted xlists' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      importer.warnings.should == []
      importer.errors.should == []
      
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.account.should eql(course.account)

      3.times do 
        importer = process_csv_data(
          "xlist_course_id,section_id,status",
          "X001,S001,deleted"
        )
        importer.warnings.should == []
        importer.errors.should == []
        
        course = @account.courses.find_by_sis_source_id("C001")
        s1 = course.course_sections.find_by_sis_source_id("S001")
        s1.should_not be_nil
        s1.nonxlist_course.should be_nil
        s1.account.should be_nil
      end
    end

    it 'should be able to move around a section and then uncrosslist back to the original' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      3.times do |i|
        importer = process_csv_data(
          "xlist_course_id,section_id,status",
          "X00#{i},S001,active"
        )
        importer.warnings.should == []
        importer.errors.should == []
        
        xlist_course = @account.courses.find_by_sis_source_id("X00#{i}")
        course = @account.courses.find_by_sis_source_id("C001")
        s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
        s1.should_not be_nil
        s1.nonxlist_course.should eql(course)
        s1.course.should eql(xlist_course)
        s1.account.should eql(course.account)
        s1.crosslisted?.should be_true
      end
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X101,S001,deleted"
      )
      importer.warnings.should == []
      importer.errors.should == []
      
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.course.should eql(course)
      s1.account.should be_nil
      s1.crosslisted?.should be_false
    end
    
    it 'should be able to handle additional section updates and not screw up the crosslisting' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.course.should eql(xlist_course)
      s1.account.should eql(course.account)
      s1.crosslisted?.should be_true
      s1.name.should == "Sec1"
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.course.should eql(xlist_course)
      s1.account.should eql(course.account)
      s1.crosslisted?.should be_true
      s1.name.should == "Sec2"
    end
    
    it 'should be able to move a non-crosslisted section between courses' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active",
        "C002,TC 102,Test Course 102,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      course1 = @account.courses.find_by_sis_source_id("C001")
      course2 = @account.courses.find_by_sis_source_id("C002")
      s1 = course1.course_sections.find_by_sis_source_id("S001")
      s1.course.should eql(course1)
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      course1.reload
      course2.reload
      s1.reload
      s1.course.should eql(course2)
    end
    
    it 'should uncrosslist a section if it is getting moved from the original course' do
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active",
        "C002,TC 102,Test Course 102,,,active"
      )
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course1 = @account.courses.find_by_sis_source_id("C001")
      course2 = @account.courses.find_by_sis_source_id("C002")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course1)
      s1.course.should eql(xlist_course)
      s1.account.should eql(course1.account)
      s1.crosslisted?.should be_true
      process_csv_data(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      s1.reload
      s1.nonxlist_course.should be_nil
      s1.course.should eql(course2)
      s1.account.should be_nil
      s1.crosslisted?.should be_false
    end

  end
  
  context 'grade publishing results importing' do
    it 'should detect bad content' do
      importer = process_csv_data(
        "enrollment_id,grade_publishing_status",
        ",published",
        "1,published",
        "1,error",
        "2,asplode")

      errors = importer.errors.map { |r| r.last }
      errors.should == ["No enrollment_id given",
                        "Duplicate enrollment id 1",
                        "Improper grade_publishing_status \"asplode\" for enrollment 2"]
    end

    it 'should properly update the db' do
      course_with_student
      @course.account = @account;
      @course.save!

      @enrollment.grade_publishing_status = 'publishing';
      @enrollment.save!

      importer = process_csv_data(
        "enrollment_id,grade_publishing_status",
        "#{@enrollment.id},published")

      importer.warnings.length.should == 0
      importer.errors.length.should == 0

      @enrollment.reload
      @enrollment.grade_publishing_status.should == 'published'
    end
  end
end
