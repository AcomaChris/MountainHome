#!/bin/bash
# Test script for Artificial Agency API using curl
# Replace YOUR_API_KEY and YOUR_PROJECT_ID with values from local_config.lua

curl -X POST https://api.artificial.agency/v1/sessions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "AA-API-Version: 2025-05-15" \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "YOUR_PROJECT_ID",
    "metadata": {
      "game-version": "0.1",
      "test-source": "mountain-home-phase1"
    }
  }'

