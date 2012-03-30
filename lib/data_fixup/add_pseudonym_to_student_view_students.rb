module DataFixup::AddPseudonymToStudentViewStudents
  def self.run
    pseudonym_join = "LEFT OUTER JOIN pseudonyms ON pseudonyms.user_id=users.id AND pseudonyms.workflow_state='active'"
    enrollment_join = "INNER JOIN enrollments ON enrollments.user_id=users.id AND enrollments.workflow_state='active' AND enrollments.type='StudentViewEnrollment'"
    begin
      fake_students = User.find(:all,
                                :select => "DISTINCT users.id, enrollments.root_account_id",
                                :joins => "#{pseudonym_join} #{enrollment_join}",
                                :conditions => "pseudonyms.id IS NULL", 
                                :limit => 1000) 
      fake_students.each do |fake_student|
        fake_student.pseudonyms.create!(:unique_id => Canvas::Security.hmac_sha1("Test Student_#{fake_student.id}")) do |p|
          p.account_id = fake_student.read_attribute(:root_account_id)
        end
      end
    end until fake_students.empty?
  end
end
