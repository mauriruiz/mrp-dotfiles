return {
  settings = {
    gopls = {
      usePlaceholders = true,
      -- Scan on demand via the go.mod codelens instead of a prompt on every change.
      vulncheck = "Off",
      directoryFilters = { "-**/node_modules" },
      -- Also type-check `//go:build integration` test files.
      buildFlags = { "-tags=integration" },
      hints = {
        compositeLiteralFields = true,
        constantValues = true,
        functionTypeParameters = true,
        ignoredError = true,
      },
    },
  },
}
