_ = require("lodash")
Promise = require "bluebird"
{ Octokit } = require("@octokit/rest")

class PullRequest
    constructor: (@data) ->

    relatedStory: () =>
        body = _.get @data, "body", ""
        capture = body.match(/(?:#)([0-9]+)/)
        storyId = _.get capture, 1
        storyIdNumber = _.toNumber storyId

        throw new Error "There is no story linked to the current pull request" unless _.isFinite storyIdNumber

        storyIdNumber

    number: () =>
        @data.number

module.exports = class GithubApi
    constructor: (token) ->
        _.assign this, new Octokit(auth: token).rest

    getPullRequestByBranch: (owner, repo, branchName) =>
        Promise.resolve(this.pulls.list({ owner, repo, head: "#{owner}:#{branchName}", state: 'open' }))
        .then ({ data: [currentPull] }) ->
            if not currentPull
                throw new Error "No pull request was found for branch #{branchName}"
            new PullRequest(currentPull)

    getPullRequestByNumber: (user, repo, number) =>
        Promise.resolve(this.pulls.get({ owner: user, repo, pull_number: number })).then ({ data }) ->
            new PullRequest(data)
        .catch (err) => throw new Error "Pull request ##{number} wasn't found"