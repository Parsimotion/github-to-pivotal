tracker = require('pivotaltracker')
GitHubApi = require("github");
_ = require("lodash")

GITHUB_USER = 'Parsimotion'
GITHUB_LOGIN_USER = 'gusTrucco'
GITHUB_LOGIN_PASSWORD = 'xxxxxxxxxxxxx'
TRACKER_TOKEN = "368271fdb6f98f3a67301591b9df3785"
TRACKER_PROJECT_ID = '799115'
BRANCH_NAME = "Nueva-branch-de-pruebe"
REPO_NAME = "github-to-pivotal"

class PullRequest
	constructor: (@data) ->

	belongsToStory: (id) =>
		@data.body.include? "[Finishes ##{id}]"

	retroMessage: =>
		body = @data.body
		title = "Retro:"
		if _.contains body, title
			body.substring(body.indexOf(title), body.length)

class Github
	cosntructor: ->
		githubApi.authenticate
			type: 'basic'
			username: GITHUB_LOGIN_USER
			password: GITHUB_LOGIN_PASSWORD

	getPullRequest: (user, repo, branchName) =>
		githubApi.pullRequests.getAll {user: user, repo: repo}, (error, pulls) ->
			return console.log error if error?
			console.log "----------------------------------------------------------------"
			console.log pulls.length
			console.log "----------------------------------------------------------------"
			data = _.find pulls, (it) => it.head.ref == branchName
			if not data
				console.log "No pull request was found for #{branchName}, will try again in 30 seconds..."
				#logica para volver a ejecutar
				console.log "No pull request was found for branch #{branchName}, aborting"
				return
			new PullRequest(data)

githubApi = new GitHubApi(version: '3.0.0')
github = new Github()
if BRANCH_NAME == "development" || BRANCH_NAME == "master"
	console.log "Doesn't make any sense to run this for #{BRANCH_NAME}. Exiting..."
	return
client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true
pullRequest = github.getPullRequest GITHUB_USER, REPO_NAME, BRANCH_NAME
console.log "----------------------------------------------------------------"
console.log pullRequest
console.log "----------------------------------------------------------------"
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