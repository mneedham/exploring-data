#!/bin/bash

echo "action,background,additionalDetails,state,signatureCount,createdAt,updatedAt,openAt,closedAt,governmentResponseAt,scheduledDebateDate,debateThresholdReachedAt,rejectedAt,debateOutcomeAt,moderationThresholdReachedAt,responseThresholdReachedAt,creatorName" > data/all_the_petitions.csv

for file in `find data/petitions -iname *.json`; do
  jq -r ".data.attributes |
  [.action,
   .background,
   .additional_details,
   .state,
   .signature_count,
   .created_at,
   .updated_at,
   .open_at,
   .closed_at,
   .government_response_at,
   .scheduled_debate_date,
   .debate_threshold_reached_at,
   .rejected_at,
   .debate_outcome_at,
   .moderation_threshold_reached_at,
   .response_threshold_reached_at,
   .creator_name] | @csv" ${file}
done >> data/all_the_petitions.csv
