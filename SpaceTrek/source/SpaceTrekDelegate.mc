import Toybox.Lang;
import Toybox.WatchUi;

class SpaceTrekDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new SpaceTrekMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onTap(clickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();

        switch (state) {
            case 0:
                // Game setup buttons
                if (inbox(xy,gridsizeXY[0],buttonWH) and grid > mingrid) {
                    grid--;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,gridsizeXY[2],buttonWH) and grid < maxgrid) {
                    grid++;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,difficultyXY[0],buttonWH) and difficulty > mindifficulty) {
                    difficulty--;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,difficultyXY[2],buttonWH) and difficulty < maxdifficulty) {
                    difficulty++;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,autoshieldsXY[2],buttonWH)) {
                    autoshields = !autoshields;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,newgameXY,newgameWH)) {
                    newgame2();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
            case 1:
                // message area - show logs
                if (inbox(xy,logXY,logWH)) {
                    showLogs();
                    WatchUi.requestUpdate();
                    return true;
                }
                // small grid = switch between sector and quadrant displays
                if (inbox(xy,smallXY,smallWH)) {
                    if (disp.equals("S")) { disp = "Q"; }
                    else { disp = "S"; }
                    action = null;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                // shields area
                if (inbox(xy,energyXY,[energyWH[0],energyWH[1]+energyWH[0]])) {
                    action = "S";
                    WatchUi.requestUpdate();
                    return true;
                }
                // information area
                if (inbox(xy,infoXY,infoWH)) {
                    var leftbutton = inbox(xy,infoXY,[infoWH[0]/2,infoWH[1]]);
                    if (action == null) {
                        if (leftbutton and health[0] < maxhealth or health[1] < maxhealth or health[2] < maxhealth) {
                            // Requesting repairs
                            action = "R";
                            WatchUi.requestUpdate();
                            return true;
                        } 
                        return false;
                    }
                    if (action.equals("I")) {
                        // Confirming impulse travel
                        return impulse(actionXY);
                    } else if (action.equals("W")) {
                        // Confirming warp travel
                        return warp(actionXY);
                    } else if (action.equals("A")) {
                        // Confirming attack
                        // left half is phasers, right half is torpedoes
                        // confirm resources (same checks as button logic)
                        if (leftbutton and energy-shields > 0) {
                            action = "P";
                            WatchUi.requestUpdate();
                            return true;
                        }
                        if (!leftbutton and torps > 0) {
                            action = "T";
                            WatchUi.requestUpdate();
                            return true;
                        }
                    } else if (action.equals("P")) {
                        // Confirming phasers
                        // left half is short burst, right half is long burst
                        // confirm resources (same checks as button logic)
                        if (leftbutton and energy-shields > 0) {
                            fire = 1;
                            state = 2;
                            savegame();
                            WatchUi.requestUpdate();
                            return true;
                        }
                        if (!leftbutton and energy-shields >= p2energy) {
                            fire = 2;
                            state = 2;
                            savegame();
                            WatchUi.requestUpdate();
                            return true;
                        }
                    } else if (action.equals("T")) {
                        // Confirming torpedoes
                        // left half is 1, right half is 2
                        // confirm resources (same checks as button logic)
                        if (leftbutton and torps > 0) {
                            fire = 1;
                            state = 2;
                            savegame();
                            WatchUi.requestUpdate();
                            return true;
                        }
                        if (!leftbutton and torps > 1) {
                            fire = 2;
                            state = 2;
                            savegame();
                            WatchUi.requestUpdate();
                            return true;
                        }
                    } else if (action.equals("S")) {
                        // Adjusting shields
                        // left half is -, right half is +
                        if (leftbutton) {
                            shields -= energy*5/100;
                        } else {
                            shields += energy*5/100;
                        }
                        if (shields > energy) { shields = energy; }
                        if (shields < 0) { shields = 0; }
                        savegame();
                        WatchUi.requestUpdate();
                        return true;
                    } else if (action.equals("D")) {
                        // Docking the ship
                        docks++;
                        energy = maxenergy;
                        torps = 10;
                        tmp = maxhealth-health[0] + maxhealth-health[1] + maxhealth-health[2] + 100;
                        tmp = tmp/100;
                        if (tmp == 1) {
                            msg = "Dock 1 day";
                        } else {
                            msg = "Dock "+tmp+" days";
                        }
                        addlog(msg);
                        days -= tmp;
                        health = [maxhealth,maxhealth,maxhealth];
                        action = null;
                        savegame();
                        WatchUi.requestUpdate();
                        return true;
                    } else if (action.equals("R")) {
                        // Repairing the ship
                        repairship();
                        action = null;
                        savegame();
                        WatchUi.requestUpdate();
                        return true;
                    } else if (action.equals("C")) {
                        // Computer
                        state = 3;
                        savegame();
                        WatchUi.requestUpdate();
                        return true;
                    }
                    return false;
                }
                action = null;
                // big grid area
                for (var i=0;i<grid;i++) {
                    for (var j=0;j<grid;j++) {
                        if (inbox(xy,[bigXY[0]+i*big1WH[0],bigXY[1]+j*big1WH[1]],big1WH)) {
                            if (disp.equals("S")) {
                                if (sect[i][j] == null) {
                                    // Moving the ship within a sector
                                    action = "I";
                                    actionXY = [i,j];
                                    WatchUi.requestUpdate();
                                    return true;
                                } else if (sect[i][j] == 0) {
                                    // Attacking an enemy
                                    action = "A";
                                    actionXY = [i,j];
                                    WatchUi.requestUpdate();
                                    return true;
                                } else if (sect[i][j] == 1 and bybase(findship())) {
                                    // Docking at a base
                                    action = "D";
                                    actionXY = [i,j];
                                    WatchUi.requestUpdate();
                                    return true;
                                } else if (sect[i][j] == 3) {
                                    action = "C";
                                    actionXY = [i,j];
                                    WatchUi.requestUpdate();
                                    return true;
                                }
                            } else {
                                // Warping the ship to a new quadrant
                                if (health[2] > 0) {
                                    action = "W";
                                    actionXY = [i,j];
                                }
                                WatchUi.requestUpdate();
                                return true;
                            }
                        }
                    }
                }
                WatchUi.requestUpdate();
                return true;
            case 3:
                // message area - show logs
                if (inbox(xy,logXY,logWH)) {
                    showLogs();
                    WatchUi.requestUpdate();
                    return true;
                }
                // new game
                if (inbox(xy,newgameXY,newgameWH)) {
                    newgame();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
        }
        return false;
    }

    function impulse(xy) {
        var sxy = findship();
        sect[sxy[0]][sxy[1]] = null;
        traveling = true;
        tmp = gridXY(sxy);
        tmp2 = gridXY(xy);
        path = [];
        var l = dist(sxy,xy);
        l = l * 2;
        var x = (tmp2[0]-tmp[0])/l;
        var y = (tmp2[1]-tmp[1])/l;
        for (var i=0;i<l;i++) {
            path.add([tmp[0]+i*x,tmp[1]+i*y]);
        }
        seg = 0;
        state = 2;
        savegame();
        WatchUi.requestUpdate();
        return true;
    }

    function warp(xy) {
        if (ship[0] == xy[0] and ship[1] == xy[1]) { return false; }
        traveling = true;
        tmp = gridXY([ship[0],ship[1]]);
        tmp2 = gridXY(xy);
        path = [];
        var l = dist(ship,xy);
        var x = (tmp2[0]-tmp[0])/l;
        var y = (tmp2[1]-tmp[1])/l;
        for (var i=0;i<l;i++) {
            path.add([tmp[0]+i*x,tmp[1]+i*y]);
        }
        seg = 0;
        state = 2;
        savegame();
        WatchUi.requestUpdate();
        return true;
    }

    // Check if a point is within a box
    // boxxy = [x,y] coordinates of upper left corner of box
    // boxwh = [w,h] width and height of box
    // point = [x,y] coordinates of point to check
    public function inbox(point,boxxy,boxwh) as Boolean {
        if (point[0]<boxxy[0]) {return false;}
        if (point[0]>boxxy[0]+boxwh[0]) {return false;}
        if (point[1]<boxxy[1]) {return false;}
        if (point[1]>boxxy[1]+boxwh[1]) {return false;}
        return true;
    }

}
