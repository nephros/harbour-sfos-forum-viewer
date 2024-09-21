import QtQuick 2.2
import Sailfish.Silica 1.0

Page { id: pollpage

    allowedOrientations: Orientation.All
    /*
      {
        "name": "poll",
        "type": "multiple",
        "status": "open",
        "results": "always",
        "min": 1, "max": 18,
        "options": [
          { "id": "d3090135d6e4050a686dac81a8e56140", "html": "Vote Option Text", "votes": 0 },
          ...
          ],
          "voters": 2,
          "chart_type": "bar",
          "title": null
       }
     */
    property var polldata // input
    /*
      { "poll": [
          "4f15caaaf5572d62cc1e4917abe25d58",
          "d3090135d6e4050a686dac81a8e56140",
          ...
        ]
      }
    */
    property var submitted_votes // input
    property string postid // input, needed to post votes
    property string key // input, needed to post votes

    property bool votemode: (polldata.status == "open") && canVote
    property bool canSubmit: { var k = Object.keys(voteTracker); return (k.length > 0) }
    property bool canVote: submitted_votes.length == 0
    property var voteTracker: ({})

    /* set a property to true if we can handle the type here.*/
    readonly property var supported: {
        "single": true,
        "multiple": true
        //"number": true // TODO: what is the name of a rating post?
    }
    property ListModel pollmodel: ListModel{}

    Component.onCompleted: {
        populate()
    }

    function populate() {
        pollmodel.clear()
        polldata.options.forEach(function(o) { pollmodel.append(o) })
        submitted_votes.poll.forEach(function(o) { voteTracker[o] = true })
    }

    SilicaListView { id: view
        anchors.fill: parent
        spacing: Theme.paddingLarge

        header: PageHeader { title: qsTr("Poll: %1").arg(polldata.title ? polldata.title : "")
                description: qsTr("Voters: %1 Type: %2 Status: %3").arg(polldata.voters).arg(polldata.type).arg(canVote ? polldata.status : qsTr("submitted"))
        }
        model: pollmodel
        delegate: Column {
            width: ListView.view.width - Theme.horizontalPageMargin
            anchors.horizontalCenter: parent.horizontalCenter
            states: [
                State { name: "vote"; when: votemode && canVote
                    PropertyChanges { target: pollSwitch; visible: true }
                    PropertyChanges { target: viewText; visible: false }
                    PropertyChanges { target: bars; visible: false }
                },
                State { name: "voted"; when: votemode && !canVote
                    PropertyChanges { target: pollSwitch; visible: true }
                    PropertyChanges { target: viewText; visible: false }
                    PropertyChanges { target: bars; visible: false }
                },
                State { name: "view"; when: !votemode
                    PropertyChanges { target: pollSwitch; visible: false }
                    PropertyChanges { target: viewText; visible: true }
                    PropertyChanges { target: bars; visible: true }
                }
            ]
            TextSwitch { id: pollSwitch
                width: parent.width
                text: html // FIXME: html is bad here
                checked: voteTracker[model.id] || false
                highlighted: down && canVote
                automaticCheck: false
                onClicked: {
                    if (!canVote) return
                    checked = !checked
                    if (polldata.type === "multiple") { // record this click
                        var va = voteTracker
                        va[model.id] = checked
                        voteTracker = new Object(va)
                        console.info("voted. ", JSON.stringify(voteTracker,null,2))
                    } else if (polldata.type === "single") { // reset uservotes to contain just this
                        var va = {}
                        va[model.id] = checked
                        voteTracker = new Object(va)
                        console.info("voted. ", JSON.stringify(voteTracker,null,2))
                    } else { // not supported
                        console.warn("click in unsupported poll mode")
                    }
                }
            }
            Label {
                visible: pollSwitch.visible
                width: parent.width
                x: pollSwitch.x + Theme.itemSizeSmall // width of the switch thingie
                textFormat: Text.PlainText
                text: qsTr("Total Votes: %1").arg(votes)
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Row { id: viewText
                width: parent.width
                Label { id: pollText
                    width: parent.width - pollNum.width
                    text: html
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                }
                Label { id: pollNum
                    text: votes
                    color: Theme.secondaryColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            // TODO: chart type *could* be "pie chart"
            Row { id: bars
                width: parent.width
                height: visible ? votebar.height : 0
                Rectangle { id: votebar
                    //property double unit: parent.width * (polldata.min/polldata.max)
                    property double unit: parent.width * (polldata.min/polldata.voters)
                    height: Theme.paddingLarge
                    width: Math.floor(unit * votes)
                    color: Theme.highlightColor
                }
                Rectangle {
                    width: parent.width - votebar.width
                    height: votebar.height
                    border.color: Theme.highlightColor
                    color: "transparent"
                }
            }
        }
        VerticalScrollDecorator {}
        ViewPlaceholder {
            enabled: !supported[polldata.type]
            text: qsTr("This type of poll is not yet supported: %1").arg(polldata.type)
        }
        PullDownMenu{
            MenuItem { id: resetMenu
                visible: canVote
                enabled: canSubmit
                text: qsTr("Reset")
                onClicked: { voteTracker = new Object({}); populate() }
            }
            MenuItem { id: submitMenu
                visible: canVote
                enabled: canSubmit
                text: qsTr("Submit")
                onClicked: {
                    // FIXME: there's surely a more javascripty way to do that:
                    // make an array of ids out of the object with "id" as property name
                    var opts = []
                    var ids = Object.keys(voteTracker)
                    ids.forEach(function(e) { if (data[e]) opts.push(e) })
                    submitPoll(key, postid, polldata.name, options)
                }
            }
            MenuItem { id: switchMenu
                text: votemode ? qsTr("View Results") : canVote ? qsTr("Vote") : qsTr("View Votes")
                onClicked: votemode = !votemode
            }
        }
    }
    /* docs seem to be missing this API.
     * according to
     * https://github.com/discourse/discourse_api/blob/main/lib/discourse_api/api/polls.rb
     * we need
     *    PUT to /polls/vote/
     *    payload: post_id, poll_name, options
     *    where poll_name is fixed "poll"
     *    and options is an array of option ids
    */
    function submitPoll(apikey, pid, name, options) {
        var xhr = new XMLHttpRequest;
        const json = { "post_id": pid, "poll_name": name, "options": options }
        console.log(JSON.stringify(json));
        xhr.open("PUT", "https://forum.sailfishos.org/polls/vote/");
        xhr.setRequestHeader("User-Api-Key", apikey);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortext: xhr.responseText});
                } else {
                    console.log(xhr.responseText);
                    pageStack.pop()
                }
            }
        }
        xhr.send(JSON.stringify(json));
    }
}
