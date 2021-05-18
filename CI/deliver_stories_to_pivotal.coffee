_ = require("lodash")
Promise = require "bluebird"
execAsync = Promise.promisify(require('child_process').exec);
tracker = require('pivotaltracker')
GithubApi = require "./githubApi"

TRACKER_TOKEN = process.argv[2]
TRACKER_PROJECT_ID = process.argv[3]
GITHUB_TOKEN = process.argv[4]
REPO_OWNER = process.argv[5]
REPO_NAME = process.argv[6]

client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true

storiesFilter = with_state: "finished"
pullSearchPattern = "git log --grep='Merge pull request #[0-9]\\+' --pretty=oneline -1 | sed -r -n 's/.*#\([0-9]*\).*/\\1/p'"

githubApi = new GithubApi(GITHUB_TOKEN)
pivotalApi = client.project(TRACKER_PROJECT_ID)

getPullNumber = () =>
	console.log "Looking for pull request number in local repo"
	execAsync pullSearchPattern
	.then(_.toNumber)
	.tap (pullNumber) => console.log "Found pull request number: ##{pullNumber}"

getPullRequest = (pullNumber) =>
	console.log "Looking for pull request in Github"
	githubApi.getPullRequestByNumber(REPO_OWNER, REPO_NAME, pullNumber)
	.tap (pullRequest) => console.log "Found pull request"

markStoryAsDelivered = (storyId) =>
	pivotalApiForStory = _.cloneDeep(pivotalApi.story(storyId));
	Promise.promisifyAll(pivotalApiForStory);
	
	pivotalApiForStory.getAsync()
	.then((story) =>
		throw new Error "Story ##{storyId} not found" unless story
		if (story.currentState == "finished")
			console.log "Marking story ##{storyId} as delivered"
			pivotalApiForStory.updateAsync current_state: "delivered"
		else
			console.log "Story ##{storyId} must be finished to be marked as delivered"
	)

getPullNumber()
.then getPullRequest
.then (pullRequest) => pullRequest.relatedStory()
.then markStoryAsDelivered