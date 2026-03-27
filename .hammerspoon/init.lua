-- put the SpoonInstall file into .hammerspoon/Spoons
hs.loadSpoon("SpoonInstall")

-- Modifier key setup
local hyper = {"cmd", "option", "shift"}

-- Function to launch or focus an app
function launchApp(appName)
    hs.application.launchOrFocus(appName)
end

-- Hotkey to open IntelliJ IDEA
hs.hotkey.bind(hyper, "J", function()
    launchApp("IntelliJ IDEA")
end)

-- Hotkey to open Chrome
hs.hotkey.bind(hyper, "K", function()
    launchApp("Google Chrome")
end)

-- Hotkey to open Chrome
hs.hotkey.bind(hyper, "L", function()
    launchApp("Slack")
end)

function open_tab(url)
  hs.osascript.javascript([[
  (function() {
    var brave = Application('Google Chrome');
    brave.activate();

    for (win of brave.windows()) {
      var tabIndex =
        win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));

      if (tabIndex != -1) {
        win.activeTabIndex = (tabIndex + 1);
        win.index = 1;
      }
    }
  })();
  ]])
end

spoon.SpoonInstall.repos.ZeroOffset = {
    url = "https://github.com/gavinest/ZeroOffset",
    desc = "ZeroOffset spoon repository",
    branch = "main",
}
spoon.SpoonInstall:andUse(
    "ZeroOffset",
    {
        repo = "ZeroOffset",
        start = true
    }
)
