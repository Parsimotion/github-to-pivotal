tracker = require('pivotaltracker')
GitHubApi = require("github");
_ = require("lodash")

GITHUB_LOGIN_USER = process.env.npm_config_githubUser
GITHUB_LOGIN_PASSWORD = npm_config_githubPassword
TRACKER_TOKEN = process.env.npm_config_trackerToken
TRACKER_PROJECT_ID = process.env.npm_config_trackerProjectId
BRANCH_NAME = process.env.npm_config_branchName
REPO_NAME = process.env.npm_config_repoName

githubApi = new GitHubApi(version: '3.0.0')
github = new Github()

if BRANCH_NAME == "development" || BRANCH_NAME == "master"
	console.log "Doesn't make any sense to run this for #{BRANCH_NAME}. Exiting..."
	return

client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true

pullRequest = github.getPullRequest GITHUB_LOGIN_USER, REPO_NAME, BRANCH_NAME

client.project(TRACKER_PROJECT_ID).stories.all {with_state: "started"}, (error, stories) ->
	_.forEach stories, (story) =>
		console.log "Searching for #{story.id} in pull request #{pull_request.number} in repo #{REPO_NAME}."
		if pullRequest.belongsToStory(story.id)
			console.log "Found #{story.id}, marking as finished."			
			retroMessage = pullRequest.retroMessage()
			if not retroMessage
				obj = {labels: story.labels, current_state = "finished"}
				obj.labels.push { name: "retro" }
			client.project(TRACKER_PROJECT_ID).story(story.id).update obj, ->
		else
			console.log "Coult not find #{story.id} in pull request."


class Github
	initialize: ->
		githubApi.authenticate
			type: 'basic'
			username: GITHUB_LOGIN_USER
			password: GITHUB_LOGIN_PASSWORD

	getPullRequest: (user, repo, branchName) =>
		githubApi.pullRequests.getAll {user: user, repo: repo, head: {ref: branchName }, state: "open"}, (error, pullRequests) ->
			data = _.find pullRequests, (it) => it.head.split(":")[2] == branchName

			if data?
				console.log "No pull request was found for branch #{branch_name}, aborting"
				return

			new PullRequest data

class PullRequest
	initialize: (@data) ->
	
	belongsToStory: (id) =>
		@data.body.include? "[Finishes ##{id}]"

	retroMessage: =>
		body = @data.body
		title = "Retro:"
		if _.contains body, title
			body.substring(body.indexOf(title), body.length)