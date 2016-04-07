#!/bin/bash

echo "link,action,background,additionalDetails,state,signatureCount,createdAt,updatedAt,openAt,closedAt,governmentResponseAt,scheduledDebateDate,debateThresholdReachedAt,rejectedAt,debateOutcomeAt,moderationThresholdReachedAt,responseThresholdReachedAt,creatorName" > data/all_the_petitions.csv

for file in `find data/petitions -iname *.json`; do
  jq -r "{attributes: .data.attributes, link: .links.self} |
  [.link,
   .attributes.action,
   .attributes.background,
   .attributes.additional_details,
   .attributes.state,
   .attributes.signature_count,
   .attributes.created_at,
   .attributes.updated_at,
   .attributes.open_at,
   .attributes.closed_at,
   .attributes.government_response_at,
   .attributes.scheduled_debate_date,
   .attributes.debate_threshold_reached_at,
   .attributes.rejected_at,
   .attributes.debate_outcome_at,
   .attributes.moderation_threshold_reached_at,
   .attributes.response_threshold_reached_at,
   .attributes.creator_name] | @csv" ${file}
done >> data/all_the_petitions.csv
