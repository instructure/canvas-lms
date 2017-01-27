import { PropTypes } from 'react'

export const courseParamsShape = {
  courseId: PropTypes.string,
  defaultInstitutionName: PropTypes.string,
  roles: PropTypes.arrayOf(PropTypes.object),
  sections: PropTypes.arrayOf(PropTypes.object)
};

export const apiStateShape = {
  pendingCount: PropTypes.number,  // number of api calls in-flight
  error: PropTypes.oneOfType([PropTypes.string, PropTypes.arrayOf(PropTypes.string)])       // error message or undefined
};

export const inputParamsShape = {
  searchType: PropTypes.oneOf(['cc_path', 'unique_id', 'sis_user_id']),
  nameList: PropTypes.string,
  role: PropTypes.string,
  section: PropTypes.string
};

export const validateResultShape = {
  users: PropTypes.array,
  duplicates: PropTypes.object,
  missing: PropTypes.object,
  errors: PropTypes.array
};

// a duplicate, as retuned from the api
export const duplicateUserShape = {
  address: PropTypes.string,
  user_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  user_name: PropTypes.string,
  account_id: PropTypes.number,
  account_name: PropTypes.string,
  email: PropTypes.string,
  login_id: PropTypes.string
};

// new person input provided by the user
export const newUserShape = {
  name: PropTypes.string,
  email: PropTypes.string
};

export const duplicateSetShape = {
  address: PropTypes.string,            // the duplicate field in this list of users
  selectedUserId: PropTypes.number,     // dflt = -1,
  skip: PropTypes.bool,                 // dflt = false,
  createNew: PropTypes.bool,            // true if selected to create a new user  for this address
  newUserInfo: PropTypes.shape(newUserShape),  // new user's info, or undefined
  userList: PropTypes.arrayOf(PropTypes.shape(duplicateUserShape)) // list as retuned from the api
};

export const duplicatesShape = {
  address: PropTypes.shape(duplicateUserShape)
}

export const missingUserShape = {
  address: PropTypes.string,
  type: PropTypes.string,      // TODO: could enumerate them, but don't know the possible values
  createNew: PropTypes.bool,   // true if selected to create a new user for this address
  newUserInfo: PropTypes.shape(newUserShape), // new user's info, or undefined
};

export const missingsShape = {
  address: PropTypes.shape(missingUserShape)
};

export const validatedUserShape = {
  address: PropTypes.string,
  user_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  user_name: PropTypes.string,
  account_id: PropTypes.number,
  account_name: PropTypes.string
};

export const personReadyToEnrollShape = {
  user_name: PropTypes.string.isRequired,
  email: PropTypes.string,
  address: PropTypes.string,
  account_name: PropTypes.string,
  account_id: PropTypes.number,
  user_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  login_id: PropTypes.string,
  sis_user_id: PropTypes.string
};

export default {
  courseParamsShape,
  apiStateShape,
  inputParamsShape,
  validateResultShape,
  duplicateSetShape,
  duplicatesShape,
  missingUserShape,
  missingsShape,
  validatedUserShape,
  personReadyToEnrollShape
};
