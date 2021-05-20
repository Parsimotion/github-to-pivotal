_ = require("lodash")
Promise = require "bluebird"
execAsync = Promise.promisify(require('child_process').exec);
GithubApi = require "./apis/githubApi"
PivotalApi = require('./apis/pivotalApi')

TRACKER_TOKEN = process.argv[2]
TRACKER_PROJECT_ID = process.argv[3]
GITHUB_TOKEN = process.argv[4]
REPO_OWNER = process.argv[5]
REPO_NAME = process.argv[6]

storiesFilter = with_state: "finished"
pullSearchPattern = "git log --grep='Merge pull request #[0-9]\\+' --pretty=oneline -1 | sed -r -n 's/.*#\([0-9]*\).*/\\1/p'"

githubApi = new GithubApi(GITHUB_TOKEN)
pivotalApi = new PivotalApi(TRACKER_PROJECT_ID, TRACKER_TOKEN)

getPullNumber = () =>
	console.log "Looking for pull request number in local repo"
	execAsync pullSearchPattern
	.then(_.toNumber)
	.tap (pullNumber) => console.log "Found pull request number: ##{pullNumber}"

getPullRequest = (pullNumber) =>
	console.log "Looking for pull request in Github"
	githubApi.getPullRequestByNumber REPO_OWNER, REPO_NAME, pullNumber
	.tap (pullRequest) => console.log "Found pull request"

markStoryAsDelivered = (storyId) =>
	pivotalApi.updateStoryStatus storyId, "finished", "delivered"

getPullNumber()
.then getPullRequest
.then (pullRequest) => pullRequest.relatedStory()
.then markStoryAsDelivered
.catch console.log