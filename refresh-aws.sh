#!/bin/bash
# =============================================================================
# AWS Credential Refresh Script for Harry
# =============================================================================
# This script refreshes AWS credentials by assuming the eks-terra-access-harry role
# Usage: ./refresh-aws.sh

set -e  # Exit on any error

echo "🔄 Refreshing AWS credentials..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Role configuration
ROLE_ARN="arn:aws:iam::436123228774:role/eks-terra-access-harry"
SESSION_NAME="terragrunt-session-$(date +%s)"

# Check if base credentials are working
echo -e "${YELLOW}🔍 Checking base AWS credentials...${NC}"
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${RED}❌ Base AWS credentials are not working. Please check your AWS CLI configuration.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Base credentials working${NC}"

# Clear any existing session tokens
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Assume role and get new credentials (4-hour duration)
echo -e "${YELLOW}🔐 Assuming role: $ROLE_ARN (4-hour session)${NC}"
CREDENTIALS=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --duration-seconds 14400 \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)

if [ $? -eq 0 ]; then
    # Parse credentials
    read -r ACCESS_KEY SECRET_KEY SESSION_TOKEN <<< "$CREDENTIALS"
    
    # Export new credentials
    export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
    export AWS_SESSION_TOKEN="$SESSION_TOKEN"
    
    echo -e "${GREEN}✅ AWS credentials refreshed successfully!${NC}"
    
    # Verify new credentials
    echo -e "${YELLOW}🔍 Verifying new credentials...${NC}"
    IDENTITY=$(aws sts get-caller-identity --query 'Arn' --output text)
    echo -e "${GREEN}✅ Authenticated as: $IDENTITY${NC}"
    
    # Show expiry information
    EXPIRY_TIME=$(($(date +%s) + 14400))  # 4 hours from now
    EXPIRY_READABLE=$(date -d "@$EXPIRY_TIME" +"%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || date -r $EXPIRY_TIME +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "~4 hours from now")
    echo -e "${YELLOW}⏰ Token expires: $EXPIRY_READABLE${NC}"
    
else
    echo -e "${RED}❌ Failed to assume role. Check your permissions.${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Ready for Terragrunt operations!${NC}"
