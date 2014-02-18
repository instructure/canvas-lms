require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/sfu/course_form/csv_builder')

describe 'A courses request' do

  context 'with commas and quotes in its name' do
    let(:funky_name) { %(A 'really', "really" funky course!) }
    it 'should be handled properly for a calendar course' do
      @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ["1141:::funk:::101:::d100:::#{funky_name}"], 2, 'kipling', '55599068', nil, nil, false)
      courses = CSV.parse(@courses_csv, :headers => true)
      courses.count.should == 1
      courses[0]['long_name'].should == "FUNK101 D100 #{funky_name}"
      courses[0]['account_id'].should == '2'
      courses[0]['term_id'].should == '1141'
    end
    it 'should be handled properly for a cross-listed course' do
      @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ["1141:::funk:::101:::d100:::#{funky_name}", '1141:::norm:::101:::d100:::Normal course'], 2, 'kipling', '55599068', nil, nil, true)
      courses = CSV.parse(@courses_csv, :headers => true)
      courses.count.should == 1
      courses[0]['long_name'].start_with?("FUNK101 D100 #{funky_name}").should == true
      courses[0]['account_id'].should == '2'
      courses[0]['term_id'].should == '1141'
    end
    it 'should be handled properly for a non-calendar course' do
      @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ["ncc-kipling-71113273-1141-#{funky_name}"], 2, 'kipling', '55599068', nil, nil, false)
      courses = CSV.parse(@courses_csv, :headers => true)
      courses.count.should == 1
      courses[0]['long_name'].should == funky_name
      courses[0]['account_id'].should == 'sfu:::ncc'
      courses[0]['term_id'].should == '1141'
    end
  end

  context 'with an excessively long cross-list' do
    it 'should fail with error' do
      lambda do
        # This course name from this cross-list is not too long due to omitted titles, but the SIS ID is.
        courses = [
            '1141:::mse:::193:::d100:::Optional Job Practicum',
            '1141:::mse:::293:::d100:::Industrial Internship I',
            '1141:::mse:::293:::d200:::Industrial Internship I',
            '1141:::mse:::294:::d100:::Special Internship I',
            '1141:::mse:::294:::d200:::Special Internship I',
            '1141:::mse:::393:::d100:::Industrial Internship II',
            '1141:::mse:::393:::d200:::Industrial Internship II',
            '1141:::mse:::394:::d100:::Special Internship II',
            '1141:::mse:::394:::d200:::Special Internship II',
            '1141:::mse:::493:::d100:::Industrial Internship III',
            '1141:::mse:::493:::d200:::Industrial Internship III',
            '1141:::mse:::493:::d300:::Industrial Internship III',
            '1141:::mse:::494:::d100:::Special Internship III',
            '1141:::mse:::494:::d200:::Special Internship III',
            '1141:::mse:::494:::d300:::Special Internship III'
        ]
        SFU::CourseForm::CSVBuilder.build('kipling', courses, 2, 'kipling', '55599068', nil, nil, true)
      end.should raise_error
    end
  end

  context 'with an excessively long name' do
    let(:long_name) { (0...256).map { (65 + rand(26)).chr }.join }
    it 'should fail with error for a calendar course' do
      lambda do
        SFU::CourseForm::CSVBuilder.build('kipling', ["1141:::long:::999:::d100:::#{long_name}"], 2, 'kipling', '55599068', nil, nil, false)
      end.should raise_error
    end
    it 'should fail with error for a cross-listed course' do
      lambda do
        SFU::CourseForm::CSVBuilder.build('kipling', ["1141:::long:::999:::d100:::#{long_name}", '1141:::shrt:::001:::d100:::Short Course'], 2, 'kipling', '55599068', nil, nil, true)
      end.should raise_error
    end
    it 'should fail with error for a non-calendar course' do
      lambda do
        SFU::CourseForm::CSVBuilder.build('kipling', ["ncc-kipling-71113273-1141-#{long_name}"], 2, 'kipling', '55599068', nil, nil, false)
      end.should raise_error
    end
  end

  # TODO: implement this
  context 'in a non-existent term' do
    it 'should fail with error for a calendar course'
    it 'should fail with error for a cross-listed course'
    it 'should fail with error for a non-calendar course'
  end

  context 'with a nil teacher SIS ID' do
    it 'should fail with error for a calendar course' do
      lambda do
        SFU::CourseForm::CSVBuilder.build('kipling', ['1141:::easy:::240:::d100:::Real Time and Embedded Systems'], 2, 'idontexist', nil, nil, nil, false)
      end.should raise_error
    end
    it 'should fail with error for a cross-listed course' do
      lambda do
        SFU::CourseForm::CSVBuilder.build('kipling', ['1141:::easy:::240:::d100:::Real Time and Embedded Systems', '1141:::hard:::840:::d100:::Real Time and Embedded Systems'], 2, 'idontexist', nil, nil, nil, true)
      end.should raise_error
    end
    it 'should fail with error for a non-calendar course' do
      lambda do
        SFU::CourseForm::CSVBuilder.build('kipling', ['ncc-kipling-71113273-1141-My special course'], 2, 'idontexist', nil, nil, nil, false)
      end.should raise_error
    end
    it 'should fail with error for a sandbox' do
      lambda do
        SFU::CourseForm::CSVBuilder.build('kipling', ['sandbox-kipling-71113273'], 2, 'idontexist', nil, nil, nil, false)
      end.should raise_error
    end
  end

end

describe 'A multiple calendar courses request' do

  before(:all) do
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', selected_courses, 2, 'kipling', '55599068', nil, nil, false)
    @courses = CSV.parse(@courses_csv, :headers => true)
    @sections = CSV.parse(@sections_csv, :headers => true)
  end

  def verify_courses(expected_course_ids)
    term = SFU::CourseForm::CSVBuilder.term('1141')
    @courses.count.should == 2
    @courses.each_with_index do |course, index|
      course['course_id'].should == expected_course_ids[index]
      course['account_id'].should == '2'
      course['term_id'].should == '1141'
      course['status'].should == 'active'
      course['start_date'].should == term.start_at.to_s
      course['end_date'].should == term.end_at.to_s
    end
  end

  def verify_sections(expected_count, expected_section_ids, expected_names, expected_course_ids)
    @sections.count.should == expected_count
    @sections.each_with_index do |section, index|
      section['section_id'].start_with?(expected_section_ids[index]).should be_true
      section['name'].should == expected_names[index]
      section['course_id'].should == expected_course_ids[index]
      section['status'].should == 'active'
      section['start_date'].should be_nil
      section['end_date'].should be_nil
    end
  end

  context 'for D100 + 2 child sections & D100 + 1 child section' do
    let(:selected_courses) { ['1141:::easy:::240:::d100:::Real Time and Embedded Systems:::d100,d101,d102', '1141:::hard:::840:::d100:::Real Time and Embedded Systems:::d100,d101'] }
    it 'should create two D100 courses' do
      verify_courses(%w(1141-easy-240-d100 1141-hard-840-d100))
    end
    it 'should create child sections only' do
      verify_sections(3, %w(1141-easy-240-d101 1141-easy-240-d102 1141-hard-840-d101), ['EASY240 D101', 'EASY240 D102', 'HARD840 D101'], %w(1141-easy-240-d100 1141-easy-240-d100 1141-hard-840-d100))
    end
  end

  context 'for D100 & D100' do
    let(:selected_courses) { ['1141:::easy:::240:::d100:::Real Time and Embedded Systems', '1141:::hard:::840:::d100:::Real Time and Embedded Systems'] }
    it 'should create two D100 courses' do
      verify_courses(%w(1141-easy-240-d100 1141-hard-840-d100))
    end
    it 'should create one D100 section each' do
      verify_sections(2, %w(1141-easy-240-d100 1141-hard-840-d100), ['EASY240 D100', 'HARD840 D100'], %w(1141-easy-240-d100 1141-hard-840-d100))
    end
  end

  context 'for D101 + 2 child sections & D001 + 1 child sections' do
    let(:selected_courses) { ['1141:::easy:::240:::d101:::Real Time and Embedded Systems:::d101,d102,d103', '1141:::hard:::840:::d001:::Real Time and Embedded Systems:::d001,d002'] }
    it 'should create D101 and D100 courses' do
      verify_courses(%w(1141-easy-240-d101 1141-hard-840-d001))
    end
    it 'should create all sections each' do
      verify_sections(5, %w(1141-easy-240-d101 1141-easy-240-d102 1141-easy-240-d103 1141-hard-840-d001 1141-hard-840-d002), ['EASY240 D101', 'EASY240 D102', 'EASY240 D103', 'HARD840 D001', 'HARD840 D002'], %w(1141-easy-240-d101 1141-easy-240-d101 1141-easy-240-d101 1141-hard-840-d001 1141-hard-840-d001))
    end
  end

  context 'for D101 & D001' do
    let(:selected_courses) { ['1141:::easy:::240:::d101:::Real Time and Embedded Systems', '1141:::hard:::840:::d001:::Real Time and Embedded Systems'] }
    it 'should create D101 and D001 courses' do
      verify_courses(%w(1141-easy-240-d101 1141-hard-840-d001))
    end
    it 'should create D101 and D001 sections' do
      verify_sections(2, %w(1141-easy-240-d101 1141-hard-840-d001), ['EASY240 D101', 'HARD840 D001'], %w(1141-easy-240-d101 1141-hard-840-d001))
    end
  end

end

describe 'A multiple calendar courses request' do

  before do
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ['1141:::easy:::240:::d100:::Real Time and Embedded Systems', '1141:::hard:::840:::d100:::Real Time and Embedded Systems'], 2, 'kipling', '55599068', teacher2_sis_id, teacher2_role, false)
    @enrollments = CSV.parse(@enrollments_csv, :headers => true)
  end

  def verify_enrollments
    @enrollments.count.should == (teacher2_sis_id.nil? ? 2 : 4)
    if teacher2_sis_id.nil?
      @enrollments[0]['course_id'].should == '1141-easy-240-d100'
      @enrollments[0]['user_id'].should == '55599068'
      @enrollments[0]['role'].should == 'teacher'
      @enrollments[1]['course_id'].should == '1141-hard-840-d100'
      @enrollments[1]['user_id'].should == '55599068'
      @enrollments[1]['role'].should == 'teacher'
    else
      @enrollments[0]['course_id'].should == '1141-easy-240-d100'
      @enrollments[0]['user_id'].should == '55599068'
      @enrollments[0]['role'].should == 'teacher'
      @enrollments[1]['course_id'].should == '1141-easy-240-d100'
      @enrollments[1]['user_id'].should == teacher2_sis_id
      @enrollments[1]['role'].should == teacher2_role
      @enrollments[2]['course_id'].should == '1141-hard-840-d100'
      @enrollments[2]['user_id'].should == '55599068'
      @enrollments[2]['role'].should == 'teacher'
      @enrollments[3]['course_id'].should == '1141-hard-840-d100'
      @enrollments[3]['user_id'].should == teacher2_sis_id
      @enrollments[3]['role'].should == teacher2_role
    end
    @enrollments.each do |enrollment|
      enrollment['section_id'].should be_nil
    end
  end

  context 'for one teacher' do
    let(:teacher2_sis_id) { nil }
    let(:teacher2_role) { nil }
    it 'should enroll the teacher to the default sections' do
      verify_enrollments
    end
  end

  context 'for two teachers' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'teacher' }
    it 'should enroll the teachers to the default sections' do
      verify_enrollments
    end
  end

  context 'for a teacher and a ta' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'ta' }
    it 'should enroll the teacher and ta to the default sections' do
      verify_enrollments
    end
  end

  context 'a teacher and a designer' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'designer' }
    it 'should enroll the teacher and designer to the default sections'  do
      verify_enrollments
    end
  end

end

describe 'A cross-list course request' do

  before do
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', selected_courses, 2, 'kipling', '55599068', nil, nil, true)
    @courses = CSV.parse(@courses_csv, :headers => true)
    @sections = CSV.parse(@sections_csv, :headers => true)
  end

  def verify_courses(expected_course_id)
    term = SFU::CourseForm::CSVBuilder.term('1141')
    @courses.count.should == 1
    @courses[0]['course_id'].should == expected_course_id
    @courses[0]['account_id'].should == '2'
    @courses[0]['term_id'].should == '1141'
    @courses[0]['status'].should == 'active'
    @courses[0]['start_date'].should == term.start_at.to_s
    @courses[0]['end_date'].should == term.end_at.to_s
  end

  def verify_sections(expected_count, expected_section_ids, expected_names, expected_course_id)
    @sections.count.should == expected_count
    @sections.each_with_index do |section, index|
      section['section_id'].start_with?(expected_section_ids[index]).should be_true
      section['name'].should == expected_names[index]
      section['course_id'].should == expected_course_id
      section['status'].should == 'active'
      section['start_date'].should be_nil
      section['end_date'].should be_nil
    end
  end

  context 'for D100 + 2 child sections / D100 + 1 child section' do
    let(:selected_courses) { ['1141:::easy:::240:::d100:::Real Time and Embedded Systems:::d100,d101,d102', '1141:::hard:::840:::d100:::Real Time and Embedded Systems:::d100,d101'] }
    it 'should create a single cross-listed D100/D100 course' do
      verify_courses('1141-easy-240-d100:1141-hard-840-d100')
    end
    it 'should create child sections only' do
      verify_sections(3, %w(1141-easy-240-d101 1141-easy-240-d102 1141-hard-840-d101), ['EASY240 D101', 'EASY240 D102', 'HARD840 D101'], '1141-easy-240-d100:1141-hard-840-d100')
    end
  end

  context 'for D100 / D100' do
    let(:selected_courses) { ['1141:::easy:::240:::d100:::Real Time and Embedded Systems', '1141:::hard:::840:::d100:::Real Time and Embedded Systems'] }
    it 'should create a single cross-listed D100/D100 course' do
      verify_courses('1141-easy-240-d100:1141-hard-840-d100')
    end
    it 'should create lecture sections only' do
      verify_sections(2, %w(1141-easy-240-d100 1141-hard-840-d100), ['EASY240 D100', 'HARD840 D100'], '1141-easy-240-d100:1141-hard-840-d100')
    end
  end

  context 'for D100 + 2 child sections / D100' do
    let(:selected_courses) { ['1141:::easy:::240:::d100:::Real Time and Embedded Systems:::d100,d101,d102', '1141:::hard:::840:::d100:::Real Time and Embedded Systems'] }
    it 'should create a single cross-listed D100/D100 course' do
      verify_courses('1141-easy-240-d100:1141-hard-840-d100')
    end
    it 'should create child sections / lecture section only' do
      verify_sections(3, %w(1141-easy-240-d101 1141-easy-240-d102 1141-hard-840-d100), ['EASY240 D101', 'EASY240 D102', 'HARD840 D100'], '1141-easy-240-d100:1141-hard-840-d100')
    end
  end

  context 'for D101 + 2 child sections / D100 + 1 child section' do
    let(:selected_courses) { ['1141:::easy:::240:::d101:::Real Time and Embedded Systems:::d101,d102,d103', '1141:::hard:::840:::d100:::Real Time and Embedded Systems:::d100,d101'] }
    it 'should create a single cross-listed D101/D100 course' do
      verify_courses('1141-easy-240-d101:1141-hard-840-d100')
    end
    it 'should create all sections / child sections only' do
      verify_sections(4, %w(1141-easy-240-d101 1141-easy-240-d102 1141-easy-240-d103 1141-hard-840-d101), ['EASY240 D101', 'EASY240 D102', 'EASY240 D103', 'HARD840 D101'], '1141-easy-240-d101:1141-hard-840-d100')
    end
  end

  context 'for D001 + 2 child sections / D100 + 1 child section' do
    let(:selected_courses) { ['1141:::easy:::240:::d001:::Real Time and Embedded Systems:::d001,d002,d003', '1141:::hard:::840:::d100:::Real Time and Embedded Systems:::d100,d101'] }
    it 'should create a single cross-listed D001/D100 course' do
      verify_courses('1141-easy-240-d001:1141-hard-840-d100')
    end
    it 'should create all sections / child sections only' do
      verify_sections(4, %w(1141-easy-240-d001 1141-easy-240-d002 1141-easy-240-d003 1141-hard-840-d101), ['EASY240 D001', 'EASY240 D002', 'EASY240 D003', 'HARD840 D101'], '1141-easy-240-d001:1141-hard-840-d100')
    end
  end

end

describe 'A cross-list course request' do

  # TODO: implement this
  context 'for courses from multiple terms' do
    it 'should fail with error'
  end

  # TODO: implement this
  context 'for a single calendar course' do
    it 'should fail with error'
  end

  # TODO: implement this
  context 'for a non-calendar course' do
    it 'should fail with error'
  end

  # TODO: implement this
  context 'for a sandbox' do
    it 'should fail with error'
  end

end

describe 'A cross-list course request' do

  before do
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ['1141:::easy:::240:::d100:::Real Time and Embedded Systems', '1141:::hard:::840:::d100:::Real Time and Embedded Systems'], 2, 'kipling', '55599068', teacher2_sis_id, teacher2_role, true)
    @enrollments = CSV.parse(@enrollments_csv, :headers => true)
  end

  def verify_enrollments
    @enrollments.count.should == (teacher2_sis_id.nil? ? 1 : 2)
    @enrollments[0]['user_id'].should == '55599068'
    @enrollments[0]['role'].should == 'teacher'
    unless teacher2_sis_id.nil?
      @enrollments[1]['user_id'].should == teacher2_sis_id
      @enrollments[1]['role'].should == teacher2_role
    end
    @enrollments.each do |enrollment|
      enrollment['course_id'].should == '1141-easy-240-d100:1141-hard-840-d100'
      enrollment['section_id'].should be_nil
    end
  end

  context 'for one teacher' do
    let(:teacher2_sis_id) { nil }
    let(:teacher2_role) { nil }
    it 'should enroll the teacher to the default section' do
      verify_enrollments
    end
  end

  context 'for two teachers' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'teacher' }
    it 'should enroll the teachers to the default section' do
      verify_enrollments
    end
  end

  context 'for a teacher and a ta' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'ta' }
    it 'should enroll the teacher and ta to the default section' do
      verify_enrollments
    end
  end

  context 'for a teacher and a designer' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'designer' }
    it 'should enroll the teacher and designer to the default section' do
      verify_enrollments
    end
  end

end

describe 'A non-calendar course request' do

  before(:all) do
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ['ncc-kipling-71113273-1141-My special course'], 2, 'kipling', '55599068', nil, nil, false)
    @courses = CSV.parse(@courses_csv, :headers => true)
    @sections = CSV.parse(@sections_csv, :headers => true)
  end

  it 'should create one course' do
    @courses.count.should == 1
    @courses[0]['course_id'].should == 'ncc-kipling-71113273'
    @courses[0]['short_name'].should == 'My special course'
    @courses[0]['long_name'].should == 'My special course'
    @courses[0]['account_id'].should == 'sfu:::ncc'
    @courses[0]['term_id'].should == '1141'
    @courses[0]['status'].should == 'active'
  end

  it 'should not create any sections' do
    @sections.count.should == 0
  end

end

describe 'A non-calendar course request' do

  before do
    @hyphenated_name = 'Introd-uction to hyphen-nation'
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ["ncc-kipling-71113273-#{term}-#@hyphenated_name"], 2, 'kipling', '55599068', nil, nil, false)
    @courses = CSV.parse(@courses_csv, :headers => true)
  end

  def verify_courses(expected_term, expected_course_name)
    @courses.count.should == 1
    @courses[0]['course_id'].should == 'ncc-kipling-71113273'
    @courses[0]['long_name'].should == expected_course_name
    @courses[0]['account_id'].should == 'sfu:::ncc'
    @courses[0]['term_id'].should == expected_term
    @courses[0]['status'].should == 'active'
  end

  context 'with hyphens in the course name' do

    let(:term) { '1141' }
    it 'should be handled properly for a specific term' do
      verify_courses(term, @hyphenated_name)
    end

    let(:term) { '' }
    it 'should be handled properly for the default term' do
      verify_courses(term, @hyphenated_name)
    end

  end

end

describe 'A non-calendar course request' do

  before do
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ['ncc-kipling-71113273-1141-My special course'], 2, 'kipling', '55599068', teacher2_sis_id, teacher2_role, false)
    @enrollments = CSV.parse(@enrollments_csv, :headers => true)
  end

  def verify_enrollments
    @enrollments.count.should == (teacher2_sis_id.nil? ? 1 : 2)
    @enrollments[0]['user_id'].should == '55599068'
    @enrollments[0]['role'].should == 'teacher'
    unless teacher2_sis_id.nil?
      @enrollments[1]['user_id'].should == teacher2_sis_id
      @enrollments[1]['role'].should == teacher2_role
    end
    @enrollments.each do |enrollment|
      enrollment['course_id'].should == 'ncc-kipling-71113273'
      enrollment['section_id'].should be_nil
    end
  end

  context 'for one teacher' do
    let(:teacher2_sis_id) { nil }
    let(:teacher2_role) { nil }
    it 'should enroll the teacher to the default section' do
      verify_enrollments
    end
  end

  context 'for two teachers' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'teacher' }
    it 'should enroll the teachers to the default section' do
      verify_enrollments
    end
  end

  context 'for a teacher and a ta' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'ta' }
    it 'should enroll the teacher and ta to the default section' do
      verify_enrollments
    end
  end

  context 'for a teacher and a designer' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'designer' }
    it 'should enroll the teacher and designer to the default section' do
      verify_enrollments
    end
  end

end

describe 'A sandbox request' do

  before(:all) do
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ['sandbox-kipling-71113273'], 2, 'kipling', '55599068', '55512345', 'teacher', false)
    @courses = CSV.parse(@courses_csv, :headers => true)
    @sections = CSV.parse(@sections_csv, :headers => true)
  end

  it 'should create one course' do
    @courses.count.should == 1
    @courses[0]['course_id'].should == 'sandbox-kipling-71113273'
    @courses[0]['account_id'].should == 'sfu:::sandbox:::instructors'
    @courses[0]['term_id'].should be_nil
    @courses[0]['status'].should == 'active'
  end

  it 'should not create any sections' do
    @sections.count.should == 0
  end

end

describe 'A sandbox request' do

  before do
    @courses_csv, @sections_csv, @enrollments_csv = SFU::CourseForm::CSVBuilder.build('kipling', ['sandbox-kipling-71113273'], 2, 'kipling', '55599068', teacher2_sis_id, teacher2_role, false)
    @enrollments = CSV.parse(@enrollments_csv, :headers => true)
  end

  def verify_enrollments
    @enrollments.count.should == (teacher2_sis_id.nil? ? 1 : 2)
    @enrollments[0]['user_id'].should == '55599068'
    @enrollments[0]['role'].should == 'teacher'
    unless teacher2_sis_id.nil?
      @enrollments[1]['user_id'].should == teacher2_sis_id
      @enrollments[1]['role'].should == teacher2_role
    end
    @enrollments.each do |enrollment|
      enrollment['course_id'].should == 'sandbox-kipling-71113273'
      enrollment['section_id'].should be_nil
    end
  end

  context 'for one teacher' do
    let(:teacher2_sis_id) { nil }
    let(:teacher2_role) { nil }
    it 'should enroll the teacher to the default section' do
      verify_enrollments
    end
  end

  context 'for two teachers' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'teacher' }
    it 'should enroll the teachers to the default section' do
      verify_enrollments
    end
  end

  context 'for a teacher and a ta' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'ta' }
    it 'should enroll the teacher and ta to the default section' do
      verify_enrollments
    end
  end

  context 'for a teacher and a designer' do
    let(:teacher2_sis_id) { '555123456' }
    let(:teacher2_role) { 'designer' }
    it 'should enroll the teacher and designer to the default section' do
      verify_enrollments
    end
  end

end
