import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All
    property string username
    property string loggedin
    property string uname
    property string avatar
    property string bio_excerpt
    property string clocation
    property string website
    property string website_name
    property string ctitle
    property string card_bg
    property string lastseen
    property string joined
    property string level
    property bool profile_hidden
    property bool can_pm

    readonly property var trustLevels: [ qsTr("New"), qsTr("Basic"), qsTr("Member"), qsTr("Regular"), qsTr("Leader") ]
    property ListModel activityModel: ListModel{}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight:  header.height + userData.height + activityHeader.height
        PageHeader {
            id: header;
            width: parent.width -header.height - Theme.paddingMedium
            title: username
            description: uname
        }
        Image {
            id: pic
            anchors.top: header.top
            anchors.left: header.right
            anchors.topMargin: Theme.paddingMedium
            anchors.rightMargin: Theme.paddingMedium
            source: application.source + avatar
        }

        Column { id: userData
            width: parent.width
            anchors.top: header.bottom
            anchors.topMargin: Theme.paddingMedium
            Label {
                id: bio
                visible: bio_excerpt !== ""
                height: bio_excerpt !== ""  ? contentHeight : 0
                anchors.margins: Theme.paddingMedium
                //anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                width: parent.width
                textFormat: Text.RichText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.WordWrap
                text: "       <style>" +
                      "a { color: %1 }".arg(Theme.highlightColor) +
                      "</style>" + bio_excerpt
                onLinkActivated: pageStack.push("OpenLink.qml", {link: link});
            }
            Label {
                id: ctit
                visible: text
                anchors.margins: Theme.paddingMedium
                //anchors.top: bio.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                width: parent.width
                textFormat: Text.RichText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.WordWrap
                text: ctitle ? ctitle : trustLevels[level]
            }
            Label {
                id: loc
                visible: clocation != ""
                height: clocation != ""? contentHeight : 0
                anchors.margins: Theme.paddingMedium
                //anchors.top: ctit.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                width: parent.width
                textFormat: Text.RichText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.WordWrap
                text: "🌎 " + clocation
            }
            Label {
                id: www
                visible: website != ""
                height: website != "" ? contentHeight : 0
                anchors.margins: Theme.paddingMedium
                //anchors.top: loc.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                width: parent.width
                textFormat: Text.RichText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.WordWrap
                text:"<style>" +
                     "a { color: %1 }".arg(Theme.highlightColor) +
                     "</style>" +  "🌐 <a href=\"" + website + "\">" + website_name + "</a>"
                onLinkActivated: pageStack.push("OpenLink.qml", {link: website});
            }
            Row {
                anchors.margins: Theme.paddingMedium
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                width: parent.width
                layoutDirection: Qt.RightToLeft 
                spacing: Theme.paddingSmall
                Label { id: seen
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Last seen: %1").arg(Qt.formatDate(new Date(lastseen)))
                    textFormat: Text.PlainText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    text: qsTr("User since: %1").arg(Qt.formatDate(new Date(joined)))
                    textFormat: Text.PlainText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                }
            }
        }

        Image {
            id: bg
            anchors.fill: userData
            source: application.source + card_bg
            opacity: 0.25
        }

        ExpandingSection {
            id: activityHeader
            anchors.top: (userData.height > 0) ? userData.bottom : header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            //anchors.topMargin: Theme.paddingMedium
            //anchors.leftMargin: Theme.horizontalPageMargin
            //anchors.rightMargin: Theme.horizontalPageMargin
            width: parent.width
            title: qsTr("Activity")
            expanded: false
            content.sourceComponent: ColumnView {
                itemHeight: Theme.itemSizeMedium*2
                maximumVisibleHeight: Screen.height-userData.height
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                model: activityModel
                delegate: ListItem {
                    anchors.topMargin: Theme.paddingSmall
                    anchors.bottomMargin: Theme.paddingSmall
                    contentHeight: preview.height
                    Component.onCompleted: { if (!topic_title || !topic_category) { gettopic(username, topic_id, index) } }
                    //onVisibleChanged: { if (visible && (!topic_title || !topic_category)) { gettopic(username, topic_id, index) } }
                    Column { id: preview
                        width: parent.width
                        property Item titlerow: titlerow
                        Row { id: titlerow
                            width: parent.width
                            height: title.height
                            Column { id: title
                                width: parent.width - topicDate.width
                                Label {
                                    width: parent.width
                                    color: Theme.highlightColor
                                    font.pixelSize: Theme.fontSizeSmall
                                    truncationMode: TruncationMode.Fade
                                    maximumLineCount: 2
                                    text: topic_title
                                }
                                Label { id: category;
                                    color: Theme.secondaryHighlightColor
                                    font.pixelSize: Theme.fontSizeTiny
                                    text: topic_category
                                }
                            }
                            Label { id: topicDate
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeTiny
                                text: formatJsonDate(created_at)
                            }
                        }
                        Label { id: content
                            text: excerpt ? excerpt : "<style> " +
                                        "del { color:" + Theme.secondaryColor + "};</style><style> " +
                                        "ins { " +
                                        "  color: " + Theme.highlightColor + ";" +
                                        "} " +
                                        "</style></p>"
                            textFormat: Text.StyledText
                            maximumLineCount: 7
                            truncationMode: TruncationMode.Fade
                            width: parent.width
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryColor
                            linkColor: Theme.primaryColor
                        }
                    }
                    onClicked: pageStack.push("ThreadView.qml",
                        {"aTitle": topic_title, "topicid": topic_id, "post_id": model.id }
                    )
                }
            }
            onExpandedChanged: {
                if (expanded && (activityModel.count == 0)) {
                    getactivity(username)
                }
            }
            BusyIndicator {
                running: activityHeader.expanded && (activityModel.count <= 0)
                size: BusyIndicatorSize.Medium
                anchors.centerIn: activityHeader
            }

        }

        function getcard(username){
            var xhr = new XMLHttpRequest;
            xhr.open("GET", application.source + "u/" + username + "/card.json");
            xhr.setRequestHeader("User-Api-Key", loggedin);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    //   console.log(xhr.responseText);
                    var data = JSON.parse(xhr.responseText);
                    var d = data.user
                    if (d.profile_hidden) profile_hidden = d.profile_hidden
                    if(d.can_send_private_message_to_user) can_pm = d.can_send_private_message_to_user
                    uname = d.name
                    avatar = d.avatar_template.replace("{size}", header.height)
                    if(d.title != null) ctitle = d.title
                    if(d.bio_excerpt) bio_excerpt = d.bio_excerpt
                    if(d.card_background_upload_url) card_bg = d.card_background_upload_url
                    if(d.website) website = d.website
                    if(d.website_name) website_name = d.website_name
                    if(d.location) clocation = d.location
                    if(d.trust_level) level = d.trust_level
                    if(d.last_seen_at) lastseen = d.last_seen_at
                    if(d.created_at) joined = d.created_at
                    //   console.log(can_pm)
                }
            }
            xhr.send()

        }
        Component.onCompleted: getcard(username)
        PullDownMenu{
            visible: can_pm
            MenuItem {
                //    visible: can_pm
                text: qsTr("PM")

                onClicked: pageStack.push("NewThread.qml", {target_recipients: username});
            }
        }
    }
    function getactivity(username) {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", application.source + "u/" + username + "/activity.json");
        xhr.setRequestHeader("User-Api-Key", loggedin);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                   console.log(xhr.responseText);
                var data = JSON.parse(xhr.responseText);
                data.forEach(function(e) {
                  e["topic_title"] = ""
                  e["topic_category"] = ""
                  activityModel.append(e)
                })
            }
        }
        xhr.send()
    }
    function gettopic(username, tid, idx) {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", application.source + "t/" + tid + ".json");
        xhr.setRequestHeader("User-Api-Key", loggedin);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                //   console.log(xhr.responseText);
                try {
                var data = JSON.parse(xhr.responseText);
                const cat = categories.lookup[data.category_id]
                if (data.title) activityModel.setProperty(idx, "topic_title", data.title)
                if (cat.name)   activityModel.setProperty(idx, "topic_category", cat.name)
                } catch(e) {}
            }
        }
        xhr.send()
    }
}
