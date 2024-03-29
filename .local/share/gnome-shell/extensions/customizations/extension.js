import GObject from "gi://GObject";
import {
  layoutManager,
  sessionMode,
} from "resource:///org/gnome/shell/ui/main.js";

export default class {
  enable() {
    global.display.get_monitor_in_fullscreen = () => false;

    const hasOverview = sessionMode.hasOverview;
    sessionMode.hasOverview = false;
    const startupComplete = layoutManager.connect("startup-complete", () => {
      layoutManager.disconnect(startupComplete);
      sessionMode.hasOverview = hasOverview;
    });

    const windowDemandsAttention = GObject.signal_handler_find(global.display, {
      signalId: "window-demands-attention",
    });
    GObject.signal_handler_block(global.display, windowDemandsAttention);
  }
}
