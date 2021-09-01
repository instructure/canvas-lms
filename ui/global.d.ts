declare global {
  interface Window {
    readonly ENV?: any
  }

  const ENV: any
}

// Global scope declarations are only allowed in module contexts, so we
// need this to make Typescript think this is a module.
export {}
