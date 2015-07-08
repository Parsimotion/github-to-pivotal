tracker = require('pivotaltracker')
GitHubApi = require("github");
_ = require("lodash")

GITHUB_USER = 'Parsimotion'
GITHUB_LOGIN_USER = 'gusTrucco'
GITHUB_LOGIN_PASSWORD = 'xxxxxxx'
TRACKER_TOKEN = "368271fdb6f98f3a67301591b9df3785"
TRACKER_PROJECT_ID = '799115'
BRANCH_NAME = "Nueva-branch-de-pruebe"
REPO_NAME = "github-to-pivotal"

class Github
	initialize: ->
		githubApi.authenticate
			type: 'basic'
			username: GITHUB_LOGIN_USER
			password: GITHUB_LOGIN_PASSWORD

	getPullRequest: (user, repo, branchName) =>
		githubApi.pullRequests.getAll {user: GITHUB_USER, repo: repo}, (error, pulls) ->
			data = _.find pulls, (it) => it.head.split(":")[2] == branchName
			if not data?
				console.log "No pull request was found for #{branchName}, will try again in 30 seconds..."
				console.log "No pull request was found for branch #{branchName}, aborting"
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

githubApi = new GitHubApi(version: '3.0.0')
github = new Github()

if BRANCH_NAME == "development" || BRANCH_NAME == "master"
	console.log "Doesn't make any sense to run this for #{BRANCH_NAME}. Exiting..."
	return

client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true

pullRequest = github.getPullRequest GITHUB_USER, REPO_NAME, BRANCH_NAME
console.log pullRequest
client.project(TRACKER_PROJECT_ID).stories.all {with_state: "started"}, (error, stories) ->
	_.forEach stories, (story) =>
		console.log "Searching for #{story.id} in pull request #{pullRequest.number} in repo #{REPO_NAME}."
		if pullRequest.belongsToStory(story.id)
			console.log "Found #{story.id}, marking as finished."			
			retroMessage = pullRequest.retroMessage()
			if not retroMessage
				obj = {labels: story.labels, current_state: "finished"}
				obj.labels.push { name: "retro" }
			client.project(TRACKER_PROJECT_ID).story(story.id).update obj, ->
		else
			console.log "Could not find #{story.id} in pull request."