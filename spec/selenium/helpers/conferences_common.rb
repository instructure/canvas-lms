# This method will select the option to delete a conference after clicking the gear menu (example: f('.icon-settings').click)
# and then delete it.
def delete_conference
  expect(f('.icon-trash.delete_conference_link.ui-corner-all')).to be_displayed
  f('.icon-trash.delete_conference_link.ui-corner-all').click
  driver.switch_to.alert.accept
  wait_for_ajaximations
end
