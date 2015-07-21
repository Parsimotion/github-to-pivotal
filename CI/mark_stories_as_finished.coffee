tracker = require('pivotaltracker')
GitHubApi = require("github");
_ = require("lodash")
Promise = require("bluebird")


TRACKER_TOKEN = process.argv[2]
TRACKER_PROJECT_ID = process.argv[3]
GITHUB_TOKEN = process.argv[4]
REPO_OWNER = process.argv[5]
REPO_NAME = process.argv[6]
BRANCH_NAME = process.argv[7]

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
    constructor: ->
        githubApi.authenticate
            type: 'oauth'
            token: GITHUB_TOKEN

    getPullRequest: (user, repo, identifier) =>
        getPull = if _.isNumber identifier then @_getPullRequestByNumber else @_getPullRequestByBranch
        getPull user, repo, identifier

    _getPullRequestByBranch: (user, repo, branchName) =>
        githubApi.pullRequests.getAllAsync(user: user, repo: repo, state: 'open').then (pulls) ->
            data = _.find pulls, (it) => it.head.ref == branchName
            if not data
                console.log "No pull request was found for branch #{branchName}, aborting"
                return
            new PullRequest(data)

    _getPullRequestByNumber: (user, repo, pullNumber) =>
        githubApi.pullRequests.getAllAsync(user: user, repo: repo, number: pullNumber).then (data) ->
            if not data
                console.log "No pull request was found for pull number #{pullNumber}, aborting"
                return
            new PullRequest(data)


githubApi = new GitHubApi(version: '3.0.0')
Promise.promisifyAll(githubApi.pullRequests);
github = new Github()
if BRANCH_NAME == "development" || BRANCH_NAME == "staging" || BRANCH_NAME == "master"
    console.log "Doesn't make any sense to run this for #{BRANCH_NAME}. Exiting..."
    return
client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true
github.getPullRequest(REPO_OWNER, REPO_NAME, BRANCH_NAME).then (pullRequest) ->
    client.project(TRACKER_PROJECT_ID).stories.all {with_state: "started"}, (error, stories) ->
        return console.log error if error?
        _.forEach stories, (story) =>
            console.log "Searching for #{story.id} in pull request #{pullRequest.data.number} in repo #{REPO_NAME}."
            if pullRequest.belongsToStory(story.id)
                console.log "Found #{story.id}, marking as finished."
                retroMessage = pullRequest.retroMessage()
                obj = {labels: story.labels, current_state: "finished"}
                if retroMessage
                    obj.labels.push { name: "retro" }
                client.project(TRACKER_PROJECT_ID).story(story.id).update obj, ->
            else
                console.log "Could not find #{story.id} in pull request."
