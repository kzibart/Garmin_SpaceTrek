import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Application.Storage;
import Toybox.Time.Gregorian;
import Toybox.Time;

var currtime;
var messageColors = [
    ["Shields",shieldcolor],
    ["Warp",shipcolor2],
    ["Dock",basecolor1],
    ["Enemy destroyed",enemycolor1],
    ["Enemy",enemycolor2],
    ["Torpedo miss",unknowncolor],
    ["Phasers miss",unknowncolor],
    ["Rammed a Star",shipcolor1],
    ["Rammed Enemy",shipcolor1],
    ["Rammed Base",shipcolor1],
    ["Torpedo hit star",starcolor2],
    ["Phasers hit star",starcolor2],
    ["Torpedo hit base",basecolor2],
    ["Phasers hit base",basecolor2],
    ["Success!",wincolor],
    ["Resign",shieldcolor],
    ["Defeat!",losecolor]
];

function showLogs() {
    if (!(Toybox.WatchUi has :CustomMenu)) { return; }
    currtime = Gregorian.info(new Time.Moment(Time.now().value()),Time.FORMAT_MEDIUM);
    var logsMenu = new WatchUi.CustomMenu(35, Graphics.COLOR_BLACK,{
        :title => new $.LogsDrawableMenuTitle(),
        :titleItemHeight => 90
    });
    for (var i=shiplog.size()-1;i>=0;i--) {
        logsMenu.addItem(new $.LogsCustomItem(i));
    }
    WatchUi.pushView(logsMenu, new $.LogsDelegate(), WatchUi.SLIDE_UP);
    WatchUi.requestUpdate();
}

class LogsDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) {
    }

    public function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class LogsDrawableMenuTitle extends WatchUi.Drawable {
    public function initialize() {
        Drawable.initialize({});
    }
    
    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
        dc.clear();
        var customThemeTitle;
        dc.drawText(dc.getWidth()/2,(dc.getHeight()*.7).toNumber(),Graphics.FONT_TINY,"Ship's Log",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setPenWidth(3);
        dc.drawLine(0,dc.getHeight(),dc.getWidth(),dc.getHeight());
    }
}

class LogsCustomItem extends WatchUi.CustomMenuItem {
    private var _id as Number;

    public function initialize(id as Number) {
        CustomMenuItem.initialize(id, {});
        _id = id;
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(0xffffff,0x000000);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var x1 = w*30/100;
        var x2 = w*35/100;
        var t = Gregorian.info(new Time.Moment(shiplog[_id][0]),Time.FORMAT_MEDIUM);
        var m = shiplog[_id][1];
        if (t.month.equals(currtime.month) and t.day.equals(currtime.day)) {
            t = t.hour+":"+t.min.format("%02d")+":"+t.sec.format("%02d");
        } else {
            t = t.month+" "+t.day;
        }
        dc.setColor(0x888888,-1);
        dc.drawText(x1, h/2, Graphics.FONT_XTINY, t, Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0xdddddd,-1);
        for (var i=0;i<messageColors.size();i++) {
            tmp = messageColors[i][0];
            if (m.substring(0,tmp.length()).equals(tmp)) {
                dc.setColor(messageColors[i][1],-1);
                break;
            }
        }
        dc.drawText(x2, h/2, Graphics.FONT_XTINY, m, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x444444,-1);
        dc.setPenWidth(2);
        dc.drawLine(0,h-1,w,h-1);
    }
}
