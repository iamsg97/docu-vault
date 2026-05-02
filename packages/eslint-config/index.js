/** @type {import('eslint').Linter.Config} */
module.exports = {
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier',
  ],
  rules: {
    // Disallow `any` — use `unknown` and narrow instead
    '@typescript-eslint/no-explicit-any': 'error',
    // Allow unused vars prefixed with _ (common for Express next/req placeholders)
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    // Return types on public API — off to reduce verbosity for internal code
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    // Enforce structured logger — console.log is banned in service code
    'no-console': 'error',
  },
  env: {
    node: true,
    es2022: true,
  },
};
