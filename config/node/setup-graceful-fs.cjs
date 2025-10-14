"use strict";

/**
 * When the frontend build spins up, rspack/i18nliner can fan out thousands of
 * synchronous `fs` reads in a tight loop. On macOS/WSL/Arch containers the
 * kernel happily enforces the per-process descriptor ceiling and Node will
 * surface `EMFILE` before we even start the dev server.
 *
 * We first try to delegate to `graceful-fs` (if it has already been installed
 * by the image) and then supplement it with our own exponential backoff
 * wrappers so the protection still applies when the dependency is unavailable.
 */
const fs = require("fs");

let gracefulFsApplied = false;
try {
  const gracefulFs = require("graceful-fs");
  if (gracefulFs && typeof gracefulFs.gracefulify === "function") {
    gracefulFs.gracefulify(fs);
    gracefulFsApplied = true;
  }
} catch (gracefulError) {
  // The module is not guaranteed to exist before `yarn install` runs. We rely
  // on the bespoke patches below in that scenario and stay quiet unless debug
  // logging is enabled to avoid noisy boot output.
  if (process.env.CANVAS_EMFILE_DEBUG?.trim()) {
    // eslint-disable-next-line no-console
    console.warn("[canvas][emfile]", "graceful-fs unavailable:", gracefulError);
  }
}

const retryableCodes = new Set(["EMFILE", "ENFILE"]);

const toPositiveInt = (value, fallback) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
};

const initialDelayMs = toPositiveInt(
  process.env.CANVAS_EMFILE_RETRY_DELAY_MS,
  25
);
const maxDelayMs = Math.max(
  initialDelayMs,
  toPositiveInt(process.env.CANVAS_EMFILE_MAX_RETRY_DELAY_MS, 1000)
);
const timeoutMs = toPositiveInt(
  process.env.CANVAS_EMFILE_RETRY_TIMEOUT_MS,
  300000
);

const waitBuffer =
  typeof SharedArrayBuffer === "function"
    ? new Int32Array(new SharedArrayBuffer(4))
    : null;

const isTruthy = (value) => {
  if (typeof value !== "string") {
    return false;
  }
  const normalized = value.trim().toLowerCase();
  return normalized !== "" && normalized !== "0" && normalized !== "false";
};

const debugEnabled = isTruthy(process.env.CANVAS_EMFILE_DEBUG);
const debugLog = (...args) => {
  if (debugEnabled) {
    const filtered = args.filter(
      (arg) => arg !== null && typeof arg !== "undefined"
    );
    // eslint-disable-next-line no-console
    console.warn("[canvas][emfile]", ...filtered);
  }
};

const sampleRuntimeState = () => {
  if (!debugEnabled) {
    return;
  }
  try {
    const handles =
      typeof process._getActiveHandles === "function"
        ? process._getActiveHandles().length
        : null;
    const requests =
      typeof process._getActiveRequests === "function"
        ? process._getActiveRequests().length
        : null;

    if (handles !== null || requests !== null) {
      debugLog(
        "runtime state",
        handles !== null ? `handles=${handles}` : null,
        requests !== null ? `requests=${requests}` : null
      );
    }
  } catch (stateError) {
    debugLog("runtime state sampling failed:", stateError);
  }
};

if (!gracefulFsApplied) {
  debugLog("graceful-fs not applied; using internal wrappers only");
}

debugLog(
  "bootstrap",
  `initialDelayMs=${initialDelayMs}`,
  `maxDelayMs=${maxDelayMs}`,
  `timeoutMs=${timeoutMs}`,
  waitBuffer ? "waitStrategy=atomics" : "waitStrategy=busy-wait"
);

const sleepSync = (ms) => {
  if (waitBuffer) {
    Atomics.wait(waitBuffer, 0, 0, ms);
  } else {
    const deadline = Date.now() + ms;
    // Busy wait fallback when SharedArrayBuffer/Atomics is unavailable.
    while (Date.now() < deadline) {
      // eslint-disable-next-line no-empty
    }
  }
};

const sleepAsync = (ms) =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

const maxInflight = toPositiveInt(
  process.env.CANVAS_EMFILE_MAX_INFLIGHT,
  256
);
const enforceMaxInflight =
  Number.isFinite(maxInflight) && maxInflight > 0;
const limitSyncConcurrency = isTruthy(
  process.env.CANVAS_EMFILE_LIMIT_SYNC
);
let inflightCount = 0;
const inflightWaiters = [];

const releaseSlot = () => {
  if (!enforceMaxInflight) {
    return;
  }
  inflightCount = Math.max(0, inflightCount - 1);
  const next = inflightWaiters.shift();
  if (next) {
    next();
  }
};

const acquireSlotSync = () => {
  if (!enforceMaxInflight) {
    return false;
  }
  while (inflightCount >= maxInflight) {
    sleepSync(1);
  }
  inflightCount += 1;
  return true;
};

const acquireSlotAsync = () => {
  if (!enforceMaxInflight) {
    return Promise.resolve();
  }
  if (inflightCount < maxInflight) {
    inflightCount += 1;
    return Promise.resolve();
  }
  return new Promise((resolve) => {
    inflightWaiters.push(() => {
      inflightCount += 1;
      resolve();
    });
  });
};

const acquireAsyncIfNeeded = enforceMaxInflight
  ? acquireSlotAsync
  : async () => {};
// Sync fs calls run on the main thread, so blocking until a slot frees
// would stall the event loop and deadlock any async work that's holding
// the limit. Default to skipping the guard for sync APIs unless an opt-in
// environment flag is set.
const acquireSyncIfNeeded =
  enforceMaxInflight && limitSyncConcurrency
    ? acquireSlotSync
    : () => {};
const releaseIfNeeded = enforceMaxInflight ? releaseSlot : () => {};

if (enforceMaxInflight) {
  debugLog("concurrency limit", `maxInFlight=${maxInflight}`);
} else {
  debugLog("concurrency limit", "unbounded");
}

const shouldRetry = (error) =>
  Boolean(error && retryableCodes.has(error.code));

const extractPath = (args) => {
  if (!args || args.length === 0) {
    return null;
  }

  const candidate = args[0];
  if (typeof candidate === "string") {
    return candidate;
  }

  if (
    candidate &&
    typeof candidate === "object" &&
    typeof candidate.path === "string"
  ) {
    return candidate.path;
  }

  if (
    candidate &&
    typeof candidate === "object" &&
    typeof candidate.fd === "number"
  ) {
    return `fd:${candidate.fd}`;
  }

  return null;
};

const patchSyncMethod = (target, methodName) => {
  const original = target?.[methodName];
  if (typeof original !== "function" || original.__canvasPatchedSync__) {
    return;
  }

  const wrapped = function patchedSyncMethod(...args) {
    const acquired = acquireSyncIfNeeded();
    let delay = initialDelayMs;
    const deadline = Date.now() + timeoutMs;
    let attempt = 0;

    try {
      // eslint-disable-next-line no-constant-condition
      while (true) {
        try {
          attempt += 1;
          return original.apply(this, args);
        } catch (error) {
          const retryable = shouldRetry(error);
          const now = Date.now();
          const timedOut = now >= deadline;
          if (!retryable || timedOut) {
            if (debugEnabled && (retryable || attempt > 1)) {
              const remaining = Math.max(deadline - now, 0);
              const reason =
                retryable && timedOut
                  ? `timeout hit; remaining=${remaining}ms`
                  : error?.code || error;
              debugLog(
                `${methodName} giving up after ${attempt} attempt${
                  attempt === 1 ? "" : "s"
                }`,
                reason
              );
            }
            throw error;
          }
          const path = extractPath(args);
          debugLog(
            `${methodName} transient ${error.code}; retry ${attempt} in ${delay}ms${
              path ? ` path=${path}` : ""
            }`
          );
          sampleRuntimeState();
          sleepSync(delay);
          delay = Math.min(delay * 2, maxDelayMs);
        }
      }
    } finally {
      if (acquired) {
        releaseIfNeeded();
      }
    }
  };

  Object.defineProperty(wrapped, "__canvasPatchedSync__", {
    value: true,
  });

  target[methodName] = wrapped;
};

const patchAsyncMethod = (target, methodName) => {
  const original = target?.[methodName];
  if (typeof original !== "function" || original.__canvasPatchedAsync__) {
    return;
  }

  const wrapped = async function patchedAsyncMethod(...args) {
    await acquireAsyncIfNeeded();
    let delay = initialDelayMs;
    const deadline = Date.now() + timeoutMs;
    let attempt = 0;

    try {
      // eslint-disable-next-line no-constant-condition
      while (true) {
        try {
          attempt += 1;
          return await original.apply(this, args);
        } catch (error) {
          const retryable = shouldRetry(error);
          const now = Date.now();
          const timedOut = now >= deadline;
          if (!retryable || timedOut) {
            if (debugEnabled && (retryable || attempt > 1)) {
              const remaining = Math.max(deadline - now, 0);
              const reason =
                retryable && timedOut
                  ? `timeout hit; remaining=${remaining}ms`
                  : error?.code || error;
              debugLog(
                `${methodName} giving up after ${attempt} attempt${
                  attempt === 1 ? "" : "s"
                }`,
                reason
              );
            }
            throw error;
          }
          const path = extractPath(args);
          debugLog(
            `${methodName} transient ${error.code}; retry ${attempt} in ${delay}ms${
              path ? ` path=${path}` : ""
            }`
          );
          sampleRuntimeState();
          await sleepAsync(delay);
          delay = Math.min(delay * 2, maxDelayMs);
        }
      }
    } finally {
      releaseIfNeeded();
    }
  };

  Object.defineProperty(wrapped, "__canvasPatchedAsync__", {
    value: true,
  });

  target[methodName] = wrapped;
};

const patchCallbackMethod = (target, methodName) => {
  const original = target?.[methodName];
  if (typeof original !== "function" || original.__canvasPatchedCallback__) {
    return;
  }

  const wrapped = function patchedCallbackMethod(...args) {
    if (args.length === 0) {
      return original.apply(this, args);
    }

    const callbackIndex = args.length - 1;
    const maybeCallback = args[callbackIndex];
    if (typeof maybeCallback !== "function") {
      return original.apply(this, args);
    }

    const restArgs = args.slice(0, callbackIndex);
    const callback = maybeCallback;
    const self = this;
    let delay = initialDelayMs;
    const deadline = Date.now() + timeoutMs;
    let attempt = 0;

    const scheduleInvoke = () => {
      Promise.resolve(acquireAsyncIfNeeded())
        .then(() => {
          attempt += 1;
          original.apply(self, [
            ...restArgs,
            function patchedCallback(error, ...cbArgs) {
              const releaseAndMaybeRetry = () => {
                releaseIfNeeded();
                setTimeout(() => {
                  delay = Math.min(delay * 2, maxDelayMs);
                  scheduleInvoke();
                }, delay);
              };

              if (!error || !shouldRetry(error)) {
                releaseIfNeeded();
                callback.call(this, error, ...cbArgs);
                return;
              }

              const now = Date.now();
              const timedOut = now >= deadline;
              if (timedOut) {
                if (debugEnabled) {
                  const remaining = Math.max(deadline - now, 0);
                  debugLog(
                    `${methodName} giving up after ${attempt} attempt${
                      attempt === 1 ? "" : "s"
                    }`,
                    `timeout hit; remaining=${remaining}ms`
                  );
                }
                releaseIfNeeded();
                callback.call(this, error, ...cbArgs);
                return;
              }

              const path = extractPath(args);
              debugLog(
                `${methodName} transient ${error.code}; retry ${attempt} in ${delay}ms${
                  path ? ` path=${path}` : ""
                }`
              );
              sampleRuntimeState();
              releaseAndMaybeRetry();
            },
          ]);
        })
        .catch((invokeError) => {
          releaseIfNeeded();
          setImmediate(() => {
            throw invokeError;
          });
        });
    };

    scheduleInvoke();
    return undefined;
  };

  Object.defineProperty(wrapped, "__canvasPatchedCallback__", {
    value: true,
  });

  target[methodName] = wrapped;
};

[
  "accessSync",
  "chmodSync",
  "chownSync",
  "lstatSync",
  "mkdirSync",
  "openSync",
  "opendirSync",
  "readFileSync",
  "readdirSync",
  "realpathSync",
  "rmSync",
  "rmdirSync",
  "statSync",
  "unlinkSync",
].forEach((method) => patchSyncMethod(fs, method));

[
  "access",
  "chmod",
  "chown",
  "lstat",
  "mkdir",
  "open",
  "opendir",
  "readFile",
  "readdir",
  "realpath",
  "rm",
  "rmdir",
  "stat",
  "unlink",
].forEach((method) => patchCallbackMethod(fs, method));

if (fs.promises) {
  [
    "access",
    "chmod",
    "chown",
    "lstat",
    "mkdir",
    "open",
    "opendir",
    "readFile",
    "readdir",
    "realpath",
    "rm",
    "rmdir",
    "stat",
    "unlink",
  ].forEach((method) => patchAsyncMethod(fs.promises, method));
}
