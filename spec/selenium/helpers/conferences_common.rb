# This method will select the option to delete a conference after clicking the gear menu (example: f('.icon-settings').click)
# and then delete it.
def delete_conference
  expect(f('.icon-trash.delete_conference_link.ui-corner-all')).to be_displayed
  f('.icon-trash.delete_conference_link.ui-corner-all').click
  driver.switch_to.alert.accept
  wait_for_ajaximations
end

def click_new_conference_btn
  f('.new-conference-btn').click
  wait_for_ajaximations
end

def create_conference(title = 'test conference')
  click_new_conference_btn
  replace_content(f('#web_conference_title'), title)
  f('.ui-dialog .btn-primary').click
  wait_for_ajaximations
end

def conclude_conference(conf)
  conf.close
  conf.save!
end

def click_gear_menu(num)
  ff('.icon-settings')[num].click
  wait_for_ajaximations
end