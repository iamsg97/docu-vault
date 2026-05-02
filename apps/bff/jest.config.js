/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/*.spec.ts'],
  setupFiles: ['./test/setup.ts'],
  moduleNameMapper: {
    '^@docuvault/shared-types(.*)$': '<rootDir>/../../packages/shared-types/src$1',
    '^@docuvault/shared-utils(.*)$': '<rootDir>/../../packages/shared-utils/src$1',
  },
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
};
