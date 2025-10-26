import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: notificationsPage
    allowedOrientations: Orientation.All
    property var notif
    property bool checkem: false
    property int pMs: 0
    property string loggedin
    property string fancy_title
    property string loggedinname
    property string highest_post_number
    property string last_read_post_number
    property string combined: application.source + "site.json" // x-discourse-username
    property string combined2: application.source + "notifications.json"
    property bool networkError: false
    property bool loadedMore: false

    // curl -L https://forum.sailfishos.org/site.json|jq .notification_types
    readonly property var fancy_type: ({
        "mentioned":                   { "name": qsTr("Mention"),      "icon": "image://theme/icon-m-bubble-universal" },
        "replied":                     { "name": qsTr("Reply"),        "icon": "image://theme/icon-m-message-reply", },
        "quoted":                      { "name": qsTr("Quote"),        "icon": "image://theme/icon-m-bubble-universal", },
        "edited":                      { "name": qsTr("Edit"),         "icon": "image://theme/icon-m-edit", },
        "liked":                       { "name": qsTr("Like"),         "icon": "image://theme/icon-m-outline-like", },
        "private_message":             { "name": qsTr("PM"),           "icon": "image://theme/icon-m-voicemail", },
        "invited_to_private_message":  { "name": qsTr("PM Invite"),    "icon": "image://theme/icon-m-voicemail", },
        "invitee_accepted":            { "name": qsTr("Accepted"),     "icon": "image://theme/icon-m-acknowledge", },
        "posted":                      { "name": qsTr("Post"),         "icon": "image://theme/icon-m-note", },
        "moved_post":                  { "name": qsTr("Moved"),        "icon": "image://theme/icon-m-message-forward", },
        "linked":                      { "name": qsTr("Link"),         "icon": "image://theme/icon-m-link", },
        "granted_badge":               { "name": qsTr("Badge"),        "icon": "" },// not displayed
        "invited_to_topic":            { "name": qsTr("Topic Invite"), "icon": "" },
        "custom":                      { "name": qsTr("Custom"),       "icon": "image://theme/icon-m-other", },
        "group_mentioned":             { "name": qsTr("Mention"),      "icon": "image://theme/icon-s-group-chat", },
        "group_message_summary":       { "name": qsTr("Group Message"),"icon": "image://theme/icon-s-group-chat", },
        "watching_first_post":         { "name": qsTr("Watched"),      "icon": "image://theme/icon-m-alarm", },
        "topic_reminder":              { "name": qsTr("Reminder"),     "icon": "image://theme/icon-m-browser-notifications", },
        "liked_consolidated":          { "name": qsTr("Consolidated"), "icon": "image://theme/icon-m-select-all", },
        "post_approved":               { "name": qsTr("Approved"),     "icon": "image://theme/icon-m-acknowledge", },
        "code_review_commit_approved": { "name": qsTr("Approved"),     "icon": "image://theme/icon-m-acknowledge", },
        "membership_request_accepted": { "name": qsTr("Accepted"),     "icon": "image://theme/icon-m-acknowledge", },
        "membership_request_consolidated":
                                       { "name": qsTr("Consolidated"),  "icon": "image://theme/icon-m-select-all", },
        "bookmark_reminder":           { "name": qsTr("Reminder"),     "icon": "" },
        "reaction":                    { "name": qsTr("Reaction"),     "icon": "" },
        "votes_released":              { "name": qsTr("Poll"),         "icon": "" },
        "event_reminder":              { "name": qsTr("Reminder"),     "icon": "image://theme/icon-m-events", },
        "event_invitation":            { "name": qsTr("Invite"),       "icon": "image://theme/icon-m-events", },
        "chat_mention":                { "name": qsTr("Mention"),      "icon": "image://theme/icon-m-outline-chat", },
        "chat_message":                { "name": qsTr("Chat"),         "icon": "image://theme/icon-m-outline-chat", },
        "chat_invitation":             { "name": qsTr("Invite"),       "icon": "image://theme/icon-m-outline-chat", },
        "chat_group_mention":          { "name": qsTr("Mention"),      "icon": "image://theme/icon-m-outline-chat", },
        "chat_quoted":                 { "name": qsTr("Quote"),        "icon": "image://theme/icon-m-outline-chat", },
        "assigned":                    { "name": qsTr("Assigned"),     "icon": "" },
        "question_answer_user_commented":
                                       { "name": qsTr("Q&A Comment"),  "icon": "image://theme/icon-m-question", },
        "watching_category_or_tag":    { "name": qsTr("Watched"),      "icon": "image://theme/icon-m-alarm", },
        "new_features":                { "name": qsTr("Feature"),      "icon": "image://theme/icon-m-setting", },
        "admin_problems":              { "name": qsTr("Admin"),        "icon": "image://theme/icon-m-warning", },
        "linked_consolidated":         { "name": qsTr("Consolidated"), "icon": "image://theme/icon-m-select-all", },
        "chat_watched_thread":         { "name": qsTr("Watched"),      "icon": "image://theme/icon-m-alarm", },
        "following":                   { "name": qsTr("Following"),    "icon": "" },
        "following_created_topic":     { "name": qsTr("Following"),    "icon": "" },
        "following_replied":           { "name": qsTr("Reply"),        "icon": "image://theme/icon-m-message-reply", },
        "circles_activity":            { "name": qsTr("Circles"),      "icon": "image://theme/icon-m-dot", }
    })

    function updateView() {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", combined);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.responseText === "") {
                    list.model.clear();
                    networkError = true;
                    return;
                } else {
                    networkError = false;
                }

                var data = JSON.parse(xhr.responseText);
                notif = data.notification_types;
            }
        }
        xhr.send();
        getnotifications();
    }
    function getPMs() {
        var xhr3 = new XMLHttpRequest;

        xhr3.open("GET", combined2);
        xhr3.setRequestHeader("User-Api-Key", loggedin);
        xhr3.onreadystatechange = function() {
            if (xhr3.readyState === XMLHttpRequest.DONE) {
                if (xhr3.responseText === "") {
                    list.model.clear();
                    networkError = true;
                    return;
                } else {
                    networkError = false;
                }

                var data = JSON.parse(xhr3.responseText);
                var topics = data.topic_list.topics;
                list.model.clear();
                var topics_length = topics.length;
                for (var i=0;i<topics_length;i++) {
                    var topic = topics[i];

                    list.model.append({ title: topic.title,
                                          username: topic.last_poster_username,
                                          topic_id: topic.id,
                                          fancy_title: topic.fancy_title,
                                          bumped: topic.bumped_at,
                                          read:  true, //topic.last_read_post_number === topic.highest_post_number ,
                                          post_number: topic.last_read_post_number
                                      });
                }
                busyind.running = false
            }
        }

        xhr3.send();
    }
    function mark(notid, index) {
        var xhr = new XMLHttpRequest;
        const json = {
            "id": notid
        };
        console.log(JSON.stringify(json),notid);
        xhr.open("PUT", application.source + "notifications/mark-read.json");
        xhr.setRequestHeader("User-Api-Key", loggedin);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortitle: xhr.status + " " + xhr.statusText, errortext: xhr.responseText});
                } else {
                    console.log(xhr.responseText)

                    list.model.setProperty(index, "read", true);
                }
            }
        }
        xhr.send(JSON.stringify(json));
    }

    function getnotifications(){
        var xhr2 = new XMLHttpRequest;

        xhr2.open("GET", combined2);
        xhr2.setRequestHeader("User-Api-Key", loggedin);
        xhr2.onreadystatechange = function() {
            if (xhr2.readyState === XMLHttpRequest.DONE){
                if(xhr2.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortitle: xhr2.status + " " + xhr2.statusText, errortext: xhr2.responseText});
                } else {
                    loggedinname = xhr2.getResponseHeader('x-discourse-username');
                    var data2 = JSON.parse(xhr2.responseText);
                    var notifications = data2.notifications;
                    var notlen = notifications.length;
                    mainConfig.setValue("lastnot", notifications[0].id);
                    for (var i=0;i<notlen;i++) {
                        var notific = notifications[i];
                        if (notific.notification_type == 16) {
                            fancy_title = "You have " + notific.data.inbox_count + " messages in your " + notific.data.group_name + " mailbox"
                            list.model.append({type: notific.notification_type, notid: notific.id,
                                                  read: notific.read, bumped: notific.created_at, post_number: notific.post_number, topic_id: notific.topic_id, fancy_title: fancy_title, username: notific.data.username})
                        } else if (notific.notification_type != 12){
                            fancy_title = notific.data.topic_title
                            var orig_name = notific.data.original_username
                            var disp_name = notific.data.display_username
                            list.model.append({ type: notific.notification_type, notid: notific.id,
                                                  read: notific.read, bumped: notific.created_at, post_number: notific.post_number, topic_id: notific.topic_id, fancy_title: fancy_title, username: orig_name ? orig_name : disp_name});
                        }
                    }
                }
            }
        }
        xhr2.send();
    }

    function resetNotificationLevel(topicid){

        var xhr = new XMLHttpRequest;
        const json = {
            "notification_level": 1
        };
        xhr.open("POST", application.source + "/t/" + topicid + "/notifications.json");
        xhr.setRequestHeader("User-Api-Key", loggedin);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortext: xhr.responseText});
                } else {
                    getPMs();
                }
            }
        }
        xhr.send(JSON.stringify(json));
    }
    onStatusChanged: {
        if (status === PageStatus.Active){
            pageStack.pushAttached(Qt.resolvedUrl("NotificationSettings.qml"));
        }
    }
    ConfigurationGroup {
        id: mainConfig
        path: "/apps/harbour-sfos-forum-viewer"

    }
    ConfigurationValue {
        id: lastnot
        key: "/apps/harbour-sfos-forum-viewer/lastnot"
    }
    SilicaListView {
        id:list
        anchors.fill: parent
        header: PageHeader {
            id: header
            title: pMs == 0 ? qsTr("Notifications") : pMs == 1 ? qsTr("PMs") : pMs == 2 ? qsTr("PMs - sent") :  qsTr("Muted topics")
            description: qsTr("SailfishOS Forum")
        }
        PullDownMenu {
            id: pms
            MenuItem {
                visible: pMs != 3
                text: qsTr("Muted topics")

                onClicked: {
                    pMs = 3
                    combined2 = application.source +"latest.json?state=muted"
                    getPMs();
                }
            }
            MenuItem {
                visible: pMs != 1
                text: qsTr("PMs")

                onClicked: {
                    pMs = 1
                    combined2 = application.source +"topics/private-messages/" + loggedinname + ".json"
                    getPMs();
                }
            }
            MenuItem {
                visible: pMs != 2
                text: qsTr("PMs - sent")

                onClicked: {
                    pMs = 2
                    combined2 = application.source +"topics/private-messages-sent/" + loggedinname + ".json"
                    getPMs();
                }
            }

            MenuItem {
                visible: pMs != 0
                text: qsTr("Notifications")

                onClicked: {
                    pMs = 0
                    combined2 = application.source + "notifications.json"
                    list.model.clear();
                    getnotifications();
                }
            }
        }
        footer: Item {
            width: parent.width
            height: Theme.horizontalPageMargin
        }

        BusyIndicator {
            id: busyind
            visible: running
            running: model.count === 0 && !networkError
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }

        ViewPlaceholder {
            enabled: model.count === 0 && networkError
            text: qsTr("Nothing to show")
            hintText: qsTr("Is the network enabled?")
        }

        model: ListModel { id: model}
        VerticalScrollDecorator {}
        Component.onCompleted: {
            updateView();
        }

        delegate: ListItem {
            id: item
            width: parent.width
            contentHeight: delegateCol.height + Theme.paddingLarge

            menu: ContextMenu {
       //         height: item.height
                hasContent:  pMs ==3
                    //        height: delegateCol.height + Theme.paddingLarge
                MenuItem {
          //          visible: pMs ==3
                    text: qsTr("Unmute")

                 onDelayedClick:   resetNotificationLevel(topic_id);
                }
            }
            Column {
                id: delegateCol
                height: childrenRect.height
                width: parent.width - Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.horizontalPageMargin
                    anchors.right: parent.right
                    spacing: 1.5*Theme.paddingMedium

                    Column {
                        width: parent.width - parent.spacing
                        Label {
                            text: username + " - " + fancy_title
                            width: parent.width
                            textFormat: Text.RichText
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.fontSizeSmall
                            color: read ? Theme.primaryColor : Theme.highlightColor
                        }
                        Row {
                            width: parent.width
                            spacing: Theme.paddingMedium
                            Icon { id: typeIcon
                                visible: !pMs
                                source: fancy_type[Object.keys(notif)[type - 1]].icon
                                width: Theme.iconSizeSmall
                                height: width
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Label {
                                id: dateLabel
                                text: formatJsonDate(bumped)
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                color: read ? Theme.secondaryColor : Theme.secondaryHighlightColor
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignLeft
                            }
                            Label {
                                visible: !pMs
                                text: fancy_type[Object.keys(notif)[type - 1]].name || Object.keys(notif)[type - 1]
                                width: parent.width - (typeIcon.width + parent.spacing + dateLabel.width + parent.spacing)
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                font.pixelSize: Theme.fontSizeSmall
                                color: read ? Theme.secondaryColor : Theme.secondaryHighlightColor
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            onClicked: {
                if(topic_id){
                    if(!read && !pMs) mark(notid, index);
                    pageStack.push("ThreadView.qml", {
                                       "topicid": topic_id,
                                       "post_number": post_number
                                   });
                }
            }
        }
    }
}

