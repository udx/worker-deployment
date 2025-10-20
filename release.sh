#!/bin/bash
set -e

VERSION_TYPE=${1:-patch}
echo "🚀 Releasing $VERSION_TYPE version..."

# npm test
npm version $VERSION_TYPE
npm publish

echo "✅ Release complete!"