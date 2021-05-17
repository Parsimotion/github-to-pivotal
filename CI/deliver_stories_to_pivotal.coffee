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

### client.project(TRACKER_PROJECT_ID).stories.all storiesFilter, (error, stories) ->
	_.forEach stories, (story) =>
		exec pullSearchPattern, (error, search_result, stderr) =>
			#console.log { error, search_result, stderr }
			process.stdout.write search_result
			if search_result.length > 0
				pullNumber = _.toNumber search_result
				console.log "Searching for #{story.id} in local pull request ##{pullNumber}"
				github.getPullRequest REPO_OWNER, REPO_NAME, BRANCH_NAME, PULL_NUMBER
				.tap(console.log)
				console.log "Found #{story.id}, marking as delivered to #{ENVIRONMENT}."
				obj = {labels: story.labels}
				obj.labels.push { name: "#{ENVIRONMENT}" }
				if isDevelopment
					obj.current_state = "delivered"
				client.project(TRACKER_PROJECT_ID).story(story.id).update obj, ->
			else
				console.log "Could not find #{story.id} in git repo." ###

githubApi = new GithubApi(GITHUB_TOKEN)
pivotalApi = client.project(TRACKER_PROJECT_ID)

getPullNumber = () =>
	console.log "Looking for pull request number in local repo"
	execAsync pullSearchPattern
	.then(_.toNumber)
	.tap (pullNumber) => console.log "Found pull request number: ##{pullNumber}"

getPullRequest = (pullNumber) =>
	console.log "Looking for pull request in Github"
	githubApi.getPullRequest(REPO_OWNER, REPO_NAME, undefined, 24)
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