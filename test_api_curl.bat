@echo off
REM Test script for Artificial Agency API using curl (Windows)
REM Replace YOUR_API_KEY and YOUR_PROJECT_ID with values from local_config.lua

curl -X POST https://api.artificial.agency/v1/sessions ^
  -H "Authorization: Bearer apikey_36zdJbGCziS40l86bmOedUHV2aL_2dTuR3LFpXYokeCuejGxqkyZHivrJIyPF" ^
  -H "AA-API-Version: 2025-05-15" ^
  -H "Content-Type: application/json" ^
  -d "{\"project_id\": \"proj_36zdPm0ecVydDJHjurno6yGO6oM\", \"metadata\": {\"game-version\": \"0.1\", \"test-source\": \"mountain-home-phase1\"}}"

