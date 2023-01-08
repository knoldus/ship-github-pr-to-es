#!/bin/bash

# get github PR details
getPrResponse=$(curl -s \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/OWNER/REPO/pulls?state=all&per_page=100&page=1")

# get number of PR
totalPR=$(echo "$getPrResponse" |
  jq '.[].number' |
  tr -d '"')

# get the loop count based on number of PRs
loopCount=$(echo "$totalPR" |
  wc -w)
echo "loopcount= $loopCount"

# get data from ES
getEsPR=$(curl -H "Content-Type: application/json" -X GET "$ES_URL/github_pr/_search?pretty" -d '{
                  "size": 10000,                                                                  
                  "query": {
                     "wildcard": {
                           "pr_number": {
                              "value": "*"
                           }}}}' |
                  jq '.hits.hits[]._source.pr_number' |
                  tr -d '"')

# store ES PR number in a temp file
echo $getEsPR | tr " " "\n" > sha_es.txt

# looping through each PR detail
for ((count = 0; count < $loopCount; count++)); do

  # get PR_number
  totalPR=$(echo "$getPrResponse" |
    jq --argjson count "$count" '.[$count].number' |
    tr -d '"')
  
  # looping through each PR detail
  matchRes=$(grep -o $totalPR sha_es.txt)
  echo $matchRes | tr " " "\n" >>match.txt

  # filtering and pushing unmatched PR number details to ES
  if [ -z $matchRes ]; then
    # get PR html url
    PrHtmlUrl=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].html_url' |
      tr -d '"')

    # get PR Body
    PrBody=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].body' |
      tr -d '"')

    # get PR Number
    PrNumber=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].number' |
      tr -d '"')

    # get PR Title
    PrTitle=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].title' |
      tr -d '"')

    # get PR state
    PrState=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].state' |
      tr -d '"')

    # get PR created at
    PrCreatedAt=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].created_at' |
      tr -d '"')

    # get PR closed at
    PrCloseAt=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].closed_at' |
      tr -d '"')

    # get PR merged at
    PrMergedAt=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].merged_at' |
      tr -d '"')

    # get base branch name
    PrBaseBranch=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].base.ref' |
      tr -d '"')

    # get source branch name
    PrSourceBranch=$(echo "$getPrResponse" |
      jq --argjson count "$count" '.[$count].head.ref' |
      tr -d '"')

    # send data to es
    curl -X POST "$ES_URL/<index>/<type>" \
      -H "Content-Type: application/json" \
      -d "{ \"pr_number\" : \"$PrNumber\",
            \"pr_url\" : \"$PrHtmlUrl\",
            \"pr_title\" : \"$PrTitle\",
            \"pr_body\" : \"$PrBody\",
            \"pr_base_branch\" : \"$PrBaseBranch\",
            \"pr_source_branch\" : \"$PrSourceBranch\",
            \"pr_state\" : \"$PrState\",
            \"pr_creation_time\" : \"$PrCreatedAt\",
            \"pr_closed_time\" : \"$PrCloseAt\",
            \"pr_merge_at\" : \"$PrMergedAt\"}"
  fi
done

# removing temporary file
rm -rf sha_es.txt
rm -rf match.txt
rm -rf unmatch.txt