_ = require("lodash")
PivotalApi = require('../apis/pivotalApi')

TRACKER_TOKEN = process.argv[2]
TRACKER_PROJECT_ID = process.argv[3]
pivotalApi = new PivotalApi(TRACKER_PROJECT_ID, TRACKER_TOKEN)

module.exports = (pullRequestGetter, currentStatus, newStatus) =>
  pullRequestGetter()
  .tap (pullRequest) => console.log "Found pull request ##{pullRequest.number()}"
  .then (pullRequest) => pullRequest.relatedStories()
  .map (storyId) =>
      console.log "Found story ##{storyId}, about to mark as #{newStatus}"
      pivotalApi.updateStoryStatus storyId, currentStatus, newStatus
      .catch console.log
  .catch console.log