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
    
    it "should use a user account even if it already has a user_id" do
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.pseudonyms.count.should == 1
      user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_1'
      
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_2,user1,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.pseudonyms.count.should == 1
      user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_2'
    end
    
    it "should use a user account even if the login_id changes" do
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.pseudonyms.count.should == 1
      user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_1'
      
      process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_2,user2,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.pseudonyms.count.should == 2
      user.pseudonyms.find_by_unique_id('user2').sis_user_id.should == 'user_2'
    end
    
  end
  
  context 'enrollment importing' do
    it 'should detect bad content' do
      before_count = Enrollment.count
      importer = process_csv_data(
        "course_id,user_id,role,section_id,status",
        ",U001,student,1B,active",
        "C001,,student,1B,active",
        "C001,U001,cheater,1B,active",
        "C001,U001,student,1B,semi-active"
      )
      Enrollment.count.should == before_count

      errors = importer.errors.map { |r| r.last }
      errors.should == ["No course_id given for an enrollment", 
                        "No user_id given for an enrollment", 
                        "Improper role \"cheater\" for an enrollment", 
                        "Improper status \"semi-active\" for an enrollment"]
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
        "user_5,user5,User,Quatro,user5@example.com,active"
      )
      process_csv_data(
        "section_id,course_id,name,status,start_date,end_date",
        "S001,test_1,Sec1,active,,"
      )
      # the enrollments
      process_csv_data(
        "course_id,user_id,role,section_name,status,associated_user_id",
        "test_1,user_1,teacher,S001,active,",
        "test_1,user_2,student,S001,active,",
        "test_1,user_3,ta,S001,active,",
        "test_1,user_5,observer,S001,active,user_2"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.teachers.first.name.should == "User Uno"
      course.students.first.name.should == "User Dos"
      course.tas.first.name.should == "User Tres"
      course.observers.first.name.should == "User Quatro"
      course.observer_enrollments.first.associated_user_id.should == course.students.first.id
    end
  end

  context 'account importing' do
    it 'should detect bad content' do
      before_count = Account.count
      importer = process_csv_data(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A001,,Humanities 2,active",
        ",,Humanities 3,active",
        "A002,A000,English,inactive",
        "A003,A001,,active"
      )
      Account.count.should == before_count

      errors = importer.errors.map { |r| r.last }
      errors.should == ["Duplicate account id A001",
                        "No account_id given for an account",
                        "Improper status \"inactive\" for account A002",
                        "Non-listed parent account referenced in csv for account A002",
                        "No name given for account A003"]
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
        "S001,C002,Sec1,,,inactive",
        "S003,C002,,,,active"
      )
      CourseSection.count.should == before_count

      errors = importer.errors.map { |r| r.last }
      errors.should == ["Duplicate section id S001 for course C001",
                        "No course_id given for a section S002",
                        "No section_id given for a section in course C001",
                        "Improper status \"inactive\" for section S001 in course C002",
                        "No name given for section S003 in course C002"]
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
  end
  
end
