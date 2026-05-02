/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/*.e2e-spec.ts'],
  // setupFiles runs before any module is loaded — env vars must be set
  // before env.ts parses process.env on first import
  setupFiles: ['./test/setup.ts'],
  moduleNameMapper: {
    '^@docuvault/shared-types(.*)$': '<rootDir>/../../packages/shared-types/src$1',
    '^@docuvault/shared-utils(.*)$': '<rootDir>/../../packages/shared-utils/src$1',
  },
};
