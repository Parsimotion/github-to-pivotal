_ = require("lodash")
Promise = require("bluebird")
GithubApi = require("./apis/githubApi")
PivotalApi = require('./apis/pivotalApi')

TRACKER_TOKEN = process.argv[2]
TRACKER_PROJECT_ID = process.argv[3]
GITHUB_TOKEN = process.argv[4]
REPO_OWNER = process.argv[5]
REPO_NAME = process.argv[6]
BRANCH_NAME = process.argv[7]

githubApi = new GithubApi GITHUB_TOKEN
pivotalApi = new PivotalApi(TRACKER_PROJECT_ID, TRACKER_TOKEN)


validateShouldRun = () =>
    if BRANCH_NAME == "development" || BRANCH_NAME == "staging" || BRANCH_NAME == "master"
        return Promise.reject (new Error "Doesn't make any sense to run this for #{BRANCH_NAME}")
    return Promise.resolve()

getPullRequest = () =>
    console.log "Looking for pull request from branch #{BRANCH_NAME} in Github"
    githubApi.getPullRequestByBranch REPO_OWNER, REPO_NAME, BRANCH_NAME
    .tap (pullRequest) => console.log "Found pull request ##{pullRequest.number()}"

markStoryAsFinished = (storyId) =>
    console.log "Found story ##{storyId}, about to mark as finished"
    pivotalApi.updateStoryStatus storyId, "started", "finished"
    .catch console.log

validateShouldRun()
.then getPullRequest
.then (pullRequest) => pullRequest.relatedStories()
.map markStoryAsFinished
.catch console.log

### storiesStatusUpdater = ($pullRequestGetter, currentStatus, newStatus) =>
    $pullRequestGetter
	.tap (pullRequest) => console.log "Found pull request ##{pullRequest.number()}"
    .then (pullRequest) => pullRequest.relatedStories()
    .map (storyId) =>
        console.log "Found story ##{storyId}, about to mark as #{newStatus}"
        pivotalApi.updateStoryStatus storyId, currentStatus, newStatus
        .catch console.log
    .catch console.log ###
