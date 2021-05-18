_ = require("lodash")
Promise = require("bluebird")
tracker = require('pivotaltracker')
GithubApi = require("./githubApi")

TRACKER_TOKEN = process.argv[2]
TRACKER_PROJECT_ID = process.argv[3]
GITHUB_TOKEN = process.argv[4]
REPO_OWNER = process.argv[5]
REPO_NAME = process.argv[6]
BRANCH_NAME = process.argv[7]

githubApi = new GithubApi()
if BRANCH_NAME == "development" || BRANCH_NAME == "staging" || BRANCH_NAME == "master"
    console.log "Doesn't make any sense to run this for #{BRANCH_NAME}. Exiting..."
    return
client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true
githubApi.getPullRequestByBranch(REPO_OWNER, REPO_NAME, BRANCH_NAME).then (pullRequest) ->
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
                console.log("About to update story ##{story.id}")
                client.project(TRACKER_PROJECT_ID).story(story.id).update obj, ->
            else
                console.log "Could not find #{story.id} in pull request."
