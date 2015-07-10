tracker = require('pivotaltracker')
GitHubApi = require("github");
_ = require("lodash")
Promise = require("bluebird")

GITHUB_USER = process.env.npm_config_githubUser
TRACKER_TOKEN = process.env.npm_config_trackerToken
TRACKER_PROJECT_ID = process.env.npm_config_trackerProjectId
BRANCH_NAME = process.env.npm_config_branchName
REPO_NAME = process.env.npm_config_repoName

class PullRequest
	constructor: (@data) ->

	belongsToStory: (id) =>
		_.includes @data.body, "[Finishes ##{id}]"

	retroMessage: =>
		body = @data.body
		title = "Retro:"
		if _.includes body, title
			body.substring(body.indexOf(title), body.length)

class Github
	getPullRequest: (user, repo, branchName) =>
		githubApi.pullRequests.getAllAsync(user: user, repo: repo, state: 'open').then (pulls) ->
			data = _.find pulls, (it) => it.head.ref == branchName
			if not data
				console.log "No pull request was found for branch #{branchName}, aborting"
				return
			new PullRequest(data)

githubApi = new GitHubApi(version: '3.0.0')
Promise.promisifyAll(githubApi.pullRequests);
github = new Github()
if BRANCH_NAME == "development" || BRANCH_NAME == "master"
	console.log "Doesn't make any sense to run this for #{BRANCH_NAME}. Exiting..."
	return
client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true
github.getPullRequest(GITHUB_USER, REPO_NAME, BRANCH_NAME).then (pullRequest) ->
	client.project(TRACKER_PROJECT_ID).stories.all {with_state: "started"}, (error, stories) ->
		return console.log error if error?
		_.forEach stories, (story) =>
			console.log "Searching for #{story.id} in pull request #{pullRequest.data.number} in repo #{REPO_NAME}."
			if pullRequest.belongsToStory(story.id)
				console.log "Found #{story.id}, marking as finished."			
				retroMessage = pullRequest.retroMessage()
				if not retroMessage
					obj = {labels: story.labels, current_state: "finished"}
					obj.labels.push { name: "retro" }
				client.project(TRACKER_PROJECT_ID).story(story.id).update obj, ->
			else
				console.log "Could not find #{story.id} in pull request."