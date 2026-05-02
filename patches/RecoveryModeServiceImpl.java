/*
 * This file is a build-time patch for Nexus Repository OSS (CORE edition).
 * It is made available under the terms of the Eclipse Public License Version 1.0,
 * which accompanies this distribution and is available at https://www.eclipse.org/legal/epl-v10.html.
 *
 * This patch is not part of the original Nexus source code and is not affiliated with
 * or endorsed by Sonatype, Inc. "Sonatype" and "Sonatype Nexus" are trademarks of Sonatype, Inc.
 */
package org.sonatype.nexus.scheduling.internal;

import jakarta.inject.Singleton;
import org.sonatype.nexus.scheduling.RecoveryModeService;
import org.springframework.stereotype.Component;

/**
 * No-op {@link RecoveryModeService} for the CORE (OSS) edition.
 *
 * Recovery mode is a Professional-edition feature. This stub ensures the Spring
 * context initialises successfully when no PRO implementation is present.
 *
 * @since 3.90
 */
@Component
@Singleton
public class RecoveryModeServiceImpl
    implements RecoveryModeService
{
  @Override
  public boolean isRecoveryMode() {
    return false;
  }

  @Override
  public void enableRecoveryMode() {
    // Not supported in CORE edition
  }

  @Override
  public void disableRecoveryMode() {
    // Not supported in CORE edition
  }

  @Override
  public void ensureNotInRecoveryMode(final String taskName) {
    // Recovery mode is never active in CORE edition
  }
}
