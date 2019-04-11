class AddPrimaryIdColumns < ActiveRecord::Migration
  def change
    tables_to_modify = %i(
      assignment_student_visibilities
      quiz_student_visibilities
    )

    tables_to_modify.each { |t| add_column t, :id, :primary_key }
  end
end
