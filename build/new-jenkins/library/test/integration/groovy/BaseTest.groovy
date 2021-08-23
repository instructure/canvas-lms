/* groovylint-disable PublicInstanceField */
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

import org.junit.rules.TestRule
import org.junit.rules.TestWatcher
import org.junit.runner.Description
import org.junit.Rule
import com.lesfurets.jenkins.unit.BasePipelineTest

class BaseTest extends BasePipelineTest {
  // Implement a rule to intercept test failures and print the callStack
  @Rule
  /* groovylint-disable-next-line UnnecessaryPublicModifier */
  public final TestRule testRule = new TestWatcher() {
    @Override
    protected void failed(Throwable e, Description description) {
      printCallStack()
    }
  }
}
