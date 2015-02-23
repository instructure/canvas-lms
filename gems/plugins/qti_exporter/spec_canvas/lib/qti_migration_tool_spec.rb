require File.expand_path(File.dirname(__FILE__) + '/../qti_helper')
if Qti.migration_executable
describe "QTI Migration Tool" do
   it "should get assessment identifier if set" do
     File.open(File.join(CANVAS_FIXTURE_DIR, 'empty_assessment.xml.qti'), 'r') do |file|
       hash = Qti.convert_xml(file.read, :file_name => "not_the_identifier.xml.qti").last.first
       expect(hash[:migration_id]).to eq 'i09d7615b43e5f35589cc1e2647dd345f'
     end
   end
   it "should use filename as identifier if none set" do
     File.open(File.join(CANVAS_FIXTURE_DIR, 'empty_assessment_no_ident.xml'), 'r') do |file|
       hash = Qti.convert_xml(file.read, :file_name => "the_identifier.xml").last.first
       expect(hash[:migration_id]).to eq 'the_identifier'
     end
   end
end
end