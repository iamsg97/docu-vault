const sharedConfig = require('@docuvault/eslint-config');

module.exports = {
  ...sharedConfig,
  parserOptions: {
    project: './tsconfig.json',
    tsconfigRootDir: __dirname,
  },
};
