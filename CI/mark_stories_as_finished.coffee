_ = require("lodash")
Promise = require("bluebird")
GithubApi = require("./apis/githubApi")
storiesStatusUpdater = require("./helpers/storiesStatusUpdater")

GITHUB_TOKEN = process.argv[4]
REPO_OWNER = process.argv[5]
REPO_NAME = process.argv[6]
BRANCH_NAME = process.argv[7]

githubApi = new GithubApi GITHUB_TOKEN

validateShouldRun = =>
    if BRANCH_NAME == "development" || BRANCH_NAME == "staging" || BRANCH_NAME == "master"
        return Promise.reject (new Error "Doesn't make any sense to run this for #{BRANCH_NAME}")
    return Promise.resolve()

getPullRequest = =>
    console.log "Looking for pull request from branch #{BRANCH_NAME} in Github"
    githubApi.getPullRequestByBranch REPO_OWNER, REPO_NAME, BRANCH_NAME

findPullRequest = =>
    validateShouldRun()
    .then getPullRequest

storiesStatusUpdater findPullRequest, "started", "finished"