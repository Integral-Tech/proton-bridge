// Copyright (c) 2023 Proton AG
// This file is part of Proton Mail Bridge.
// Proton Mail Bridge is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// Proton Mail Bridge is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with Proton Mail Bridge. If not, see <https://www.gnu.org/licenses/>.
import QtQml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    enum Client {
        AppleMail,
        MicrosoftOutlook,
        MozillaThunderbird,
        Generic
    }
    enum ContentStack {
        Onboarding,
        Login,
        ClientConfigSelector,
        ClientConfigAppleMail
    }
    enum RootStack {
        TwoPanesView,
        ClientConfigParameters,
        ClientConfigEnd
    }

    property string address
    property var backAction: null
    property int client
    property ColorScheme colorScheme
    property var user

    signal bugReportRequested
    signal wizardEnded

    function showBugReport() {
        closeWizard()
        bugReportRequested()
    }

    function _showClientConfig() {
        showClientConfig(root.user, root.address);
    }
    function clientIconSource() {
        switch (client) {
        case SetupWizard.Client.AppleMail:
            return "/qml/icons/ic-apple-mail.svg";
        case SetupWizard.Client.MicrosoftOutlook:
            return "/qml/icons/ic-microsoft-outlook.svg";
        case SetupWizard.Client.MozillaThunderbird:
            return "/qml/icons/ic-mozilla-thunderbird.svg";
        case SetupWizard.Client.Generic:
            return "/qml/icons/ic-other-mail-clients.svg";
        default:
            console.error("Unknown mail client " + client);
            return "/qml/icons/ic-other-mail-clients.svg";
        }
    }
    function clientName() {
        switch (client) {
        case SetupWizard.Client.AppleMail:
            return "Apple Mail";
        case SetupWizard.Client.MicrosoftOutlook:
            return "Outlook";
        case SetupWizard.Client.MozillaThunderbird:
            return "Thunderbird";
        case SetupWizard.Client.Generic:
            return qsTr("your email client");
        default:
            console.error("Unknown mail client " + client);
            return qsTr("your email client");
        }
    }
    function closeWizard() {
        wizardEnded();
    }
    function showAppleMailAutoConfig() {
        backAction = _showClientConfig;
        rootStackLayout.currentIndex = SetupWizard.RootStack.TwoPanesView;
        rightContent.currentIndex = SetupWizard.ContentStack.ClientConfigAppleMail;
        clientConfigAppleMail.showAutoconfig(); // This will trigger signals that will display the appropriate left content.
    }
    function showClientConfig(user, address) {
        backAction = null;
        root.user = user;
        root.address = address;
        rootStackLayout.currentIndex = SetupWizard.RootStack.TwoPanesView;
        leftContent.showClientSelector();
        rightContent.currentIndex = SetupWizard.ContentStack.ClientConfigSelector;
    }
    function showClientConfigEnd() {
        backAction = null;
        rootStackLayout.currentIndex = SetupWizard.RootStack.ClientConfigEnd;
    }
    function showClientParams() {
        backAction = _showClientConfig;
        rootStackLayout.currentIndex = SetupWizard.RootStack.ClientConfigParameters;
    }
    function showLogin(username = "") {
        backAction = null;
        rootStackLayout.currentIndex = SetupWizard.RootStack.TwoPanesView;
        root.address = "";
        leftContent.showLogin();
        rightContent.currentIndex = SetupWizard.ContentStack.Login;
        login.username = username;
        login.reset(false);
    }
    function showOnboarding() {
        backAction = null;
        rootStackLayout.currentIndex = SetupWizard.RootStack.TwoPanesView;
        root.address = "";
        root.user = null;
        leftContent.showOnboarding();
        rightContent.currentIndex = SetupWizard.ContentStack.Onboarding;
    }

    Connections {
        function onLoginFinished(userIndex, wasSignedOut) {
            if (wasSignedOut) {
                closeWizard();
                return;
            }
            let user = Backend.users.get(userIndex);
            let address = user ? user.addresses[0] : "";
            showClientConfig(user, address);
        }

        target: Backend
    }
    StackLayout {
        id: rootStackLayout
        anchors.fill: parent

        // rootStackLayout index 0
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 0

            Rectangle {
                id: leftHalf
                Layout.fillHeight: true
                Layout.fillWidth: true
                color: root.colorScheme.background_norm

                LeftPane {
                    id: leftContent
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 92
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 40
                    clip: true
                    width: 364
                    wizard: root

                    Connections {
                        function onAppleMailAutoconfigCertificateInstallPageShown() {
                            leftContent.showAppleMailAutoconfigCertificateInstall();
                        }
                        function onAppleMailAutoconfigProfileInstallPageShow() {
                            leftContent.showAppleMailAutoconfigProfileInstall();
                        }

                        target: clientConfigAppleMail
                    }
                }
                Image {
                    id: mailLogoWithWordmark
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 36
                    source: root.colorScheme.mail_logo_with_wordmark
                    sourceSize.height: 36
                    sourceSize.width: 134
                    width: 134
                }
            }
            Rectangle {
                id: rightHalf
                Layout.fillHeight: true
                Layout.fillWidth: true
                color: root.colorScheme.background_weak

                StackLayout {
                    id: rightContent
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 92
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 40
                    clip: true
                    currentIndex: 0
                    width: 364

                    // rightContent stack index 0
                    Onboarding {
                        wizard: root
                    }

                    // rightContent tack index 1
                    Login {
                        id: login
                        wizard: root

                        onLoginAbort: {
                            root.closeWizard();
                        }
                    }

                    // rightContent stack index 2
                    ClientConfigSelector {
                        id: clientConfigSelector
                        wizard: root
                    }
                    // rightContent stack index 3
                    ClientConfigAppleMail {
                        id: clientConfigAppleMail
                        wizard: root
                    }
                }
            }
        }

        // rootStackLayout index 1
        ClientConfigParameters {
            id: clientConfigParameters
            Layout.fillHeight: true
            Layout.fillWidth: true
            wizard: root
        }

        // rootStackLayout index 2
        ClientConfigEnd {
            id: clientConfigEnd
            Layout.fillHeight: true
            Layout.fillWidth: true
            wizard: root
        }
    }
    HelpButton {
        wizard: root
    }
    Button {
        id: backButton
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.top: parent.top
        anchors.topMargin: 40
        colorScheme: root.colorScheme
        icon.source: "/qml/icons/ic-chevron-left.svg"
        iconOnTheLeft: true
        secondary: true
        secondaryIsOpaque: true
        spacing: 8
        text: qsTr("Back")
        visible: backAction != null

        onClicked: {
            if (backAction) {
                backAction();
            }
        }
    }
}

