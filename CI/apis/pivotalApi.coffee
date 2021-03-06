_ = require "lodash"
Promise = require("bluebird")
PivotalSdk = require('pivotaltracker').Client

module.exports = class PivotalApi
    constructor: (projectId, token) ->
        pivotalSdk = new PivotalSdk(token);
        pivotalSdk.use_ssl = true
        _.assign @, pivotalSdk: pivotalSdk.project(projectId)

    updateStoryStatus: (storyId, currentStatus, newStatus) =>
        @_getStory storyId
        .then (story) =>
            throw new Error "Story ##{storyId} not found" unless story
            
            if (currentStatus is 'finished' and story.storyType is 'chore')
                currentStatus = 'started'
                newStatus = 'accepted'
            
            if (story.currentState == currentStatus)
                console.log "Marking story ##{storyId} as #{newStatus}"
                @_updateStory storyId, current_state: newStatus
            else
                Promise.reject new Error "Story ##{storyId} should be #{currentStatus} to be marked as #{newStatus}, but now it's #{story.currentState}"

    _getStory: (storyId) =>
        @_storyApi storyId
        .getAsync()

    _updateStory: (storyId, newState) =>
        @_storyApi storyId
        .updateAsync newState

    _storyApi: (storyId) =>
        storyApi = _.cloneDeep(@pivotalSdk.story(storyId))
        Promise.promisifyAll(storyApi);

        storyApi