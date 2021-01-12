/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import org.junit.Before
import org.junit.Test

class RebaseHelperTest extends BaseTest {

  def rebaseHelper
  def GERRIT_BRANCH = "branch"
  def GERRIT_REFSPEC = "refs/changes/72/254472/3"
  def DEFAULT_COMMIT_HISTORY = 100
  def DEFAULT_ENV = [
    CANVAS_BUILDS_REFSPEC: "master",
    GERRIT_REFSPEC: GERRIT_REFSPEC,
    GERRIT_BRANCH: GERRIT_BRANCH
  ]

  @Before
  void setUp() throws Exception {
    super.setUp()
    binding.setVariable('env', DEFAULT_ENV)
    rebaseHelper = loadScript("vars/rebaseHelper.groovy")
    binding.setProperty('git', rebaseHelper)
    helper.registerAllowedMethod('fetch', [String, Integer], {true})
    helper.registerAllowedMethod('hasCommonAncestor', [String], {true})
    helper.registerAllowedMethod('rebase', [String], {true})
  }

  @Test
  void "rebaseHelper should error if hasCommonAncestor fails" () throws Exception {
    helper.registerAllowedMethod('hasCommonAncestor', [String], {false})
    rebaseHelper("master")
    assertCallStack().contains("error(Error: your branch is over 100 commits behind master, please rebase your branch manually.)")
  }

  @Test
  void "rebaseHelper should use the commitHistory passed as argument"() throws Exception {
    rebaseHelper("branch", 20)
    assertCallStack().contains("fetch(branch, 20)")
  }

  @Test
  void "rebaseHelper should error if rebase fails"() throws Exception {
    helper.registerAllowedMethod('rebase', [String], {false})
    rebaseHelper("branch", 20)
    assertCallStack().contains("Error: Rebase couldn't resolve changes automatically, please resolve these conflicts locally.")
  }

  @Test
  void "rebaseHelper should rebase also on master if a dev branch is passed"() throws Exception {
    rebaseHelper("dev/test")
    assertCallStack().contains("fetch(dev/test, ${DEFAULT_COMMIT_HISTORY})")
    assertCallStack().contains("fetch(master, ${DEFAULT_COMMIT_HISTORY})")
  }
}
