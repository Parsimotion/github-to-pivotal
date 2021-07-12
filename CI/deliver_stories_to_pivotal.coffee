_ = require("lodash")
Promise = require "bluebird"
GithubApi = require "./apis/githubApi"
execAsync = Promise.promisify(require('child_process').exec);
storiesStatusUpdater = require("./helpers/storiesStatusUpdater")

GITHUB_TOKEN = process.argv[4]
REPO_OWNER = process.argv[5]
REPO_NAME = process.argv[6]

pullSearchPattern = "git log --grep='Merge pull request #[0-9]\\+' --pretty=oneline -1 | sed -r -n 's/.*#\([0-9]*\).*/\\1/p'"

githubApi = new GithubApi(GITHUB_TOKEN)

getPullNumber = () =>
	console.log "Looking for pull request number in local repo"
	execAsync pullSearchPattern
	.then(_.toNumber)
	.tap (pullNumber) => console.log "Found pull request number: ##{pullNumber}"

getPullRequest = (pullNumber) =>
	console.log "Looking for pull request in Github"
	githubApi.getPullRequestByNumber REPO_OWNER, REPO_NAME, pullNumber

findPullRequest = =>
	getPullNumber()
	.then getPullRequest

storiesStatusUpdater findPullRequest, "finished", "delivered"