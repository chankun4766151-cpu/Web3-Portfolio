#!/bin/bash

echo "=========================================="
echo "ETH Call Option Token - Setup Script"
echo "=========================================="
echo ""

# Step 1: Initialize Git
echo "Step 1: Initializing Git repository..."
git init
echo ""

# Step 2: Install dependencies
echo "Step 2: Installing dependencies..."
echo "  - Installing forge-std..."
forge install foundry-rs/forge-std --no-commit

echo "  - Installing OpenZeppelin contracts..."
forge install OpenZeppelin/openzeppelin-contracts --no-commit
echo ""

# Step 3: Build contracts
echo "Step 3: Compiling contracts..."
forge build
echo ""

# Step 4: Run tests
echo "Step 4: Running tests..."
forge test -vvvv
echo ""

echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review the test output above"
echo "2. Take screenshots of the test logs"
echo "3. Push to GitHub:"
echo "   git add ."
echo "   git commit -m 'Complete ETH Call Option Token'"
echo "   git remote add origin <your-repo-url>"
echo "   git push -u origin main"
