import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Math;
import Toybox.Application.Storage;
import Toybox.Timer;
import Toybox.Time;

// quad is [enemies,bases,stars]
// sect has 0=enemy, 1=base, 2=star, 3=us

var DS = System.getDeviceSettings();
var SW = DS.screenWidth;
var SH = DS.screenHeight;
var centerX = SW/2;
var centerY = SH/2;

var game,state,quad,scanned,sect,esect,ship,shipSect,energy,shields,health,torps,days,enemies,disp,docks,dtaken,ddealt,shiplog;
var action,actionXY,destroyXY;
var bigXY,bigWH,big1WH;
var smallXY,smallWH,small1WH;
var infoXY,infoWH,msgXY;
var torpsXY,torpsWH;
var energyXY,energyWH;
var titleXY,titleWH;
var gridsizeXY,difficultyXY,autoshieldsXY,buttonWH;
var resultsXY,statsX,statsY,statsgX,statsWH;
var newgameXY,newgameWH,logXY,logWH;

var gridcolor1 = 0xffffff;
var gridcolor2 = 0x888888;
var alertcolor = 0xff0000;
var starcolor1 = 0xfff1cc;
var starcolor2 = 0xfce62e;
var shipcolor1 = 0xc7c8cd;
var shipcolor2 = 0x7d7f8e;
var shieldcolor = 0x7eb7fc;
var basecolor1 = 0x6d93b6;
var basecolor2 = 0x476a9e;
var enemycolor1 = 0x5d9058;
var enemycolor2 = 0x306424;
var labelcolor = 0xdddddd;
var selectcolor = 0xffff00;
var movecolor = 0x00ff00;
var attackcolor = 0xff0000;
var torpcolor1 = 0xf3fee8;
var torpcolor2 = 0xca7b66;
var phasercolor1 = 0xff0000;
var phasercolor2 = 0xffa0a0;
var disruptcolor1 = 0x00ff00;
var disruptcolor2 = 0xa0ffa0;
var energycolor = 0xffff00;
var enginecolor1 = shieldcolor;
var enginecolor2 = shipcolor2;
var dockcolor = basecolor2;
var buttoncolord = 0x1a331d;
var buttoncolorl = 0x2e5c34;
var buttoncolor = 0x244829;
var buttonlabelcolor = 0xdddddd;
var unknowncolor = 0x444444;
var brokencolor = 0x482424;
var titlecolor = 0xf9d423;
var wincolor = 0x00ff00;
var losecolor = 0xff0000;
var starfieldcolors = [0xc6c6c8, 0x808082, 0x5d6770, 0x9d9ca1, 0x6d7d95, 0xd1d1d3, 0x565658];

var mydc,tmp,tmp2,tmp3,tmp4,tmp5,thisQuad,fire,timer,path,seg,deseg,so;
var center = Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER;
var left = Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER;
var right = Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER;
var msg = null;
var msgcolor = labelcolor;
var firing = false;
var traveling = false;
var destroying = false;
var justwarped = false;
var wait = null;
var lastmsg = new Time.Moment(0);
var msgwait = new Time.Duration(2);
var starfield = null;
var settingshields = 0;

var grid = 6;
var mingrid = 4;
var maxgrid = 8;
var difficulty = 1;
var mindifficulty = 0;
var maxdifficulty = 2;
var autoshields = true;
var enemyenergy = 300;
var p2energy = 100;
var maxhealth = 500;
var maxenemies,maxdays,bases,maxenergy;

class SpaceTrekView extends WatchUi.View {

    function initialize() {
System.println("initialize called");
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
System.println("onLayout called");

//newgame();  // for testing

        if (Toybox.Graphics has :createBufferedBitmap) {
            starfield = Graphics.createBufferedBitmap({:width=>SW,:height=>SH}).get();
            buildstarfield(starfield.getDc());
        } else {
            starfield = null;
        }

        so = SW*4/300;
        if (so < 1) { so = 1; }
        action = null;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        mydc = dc;
        mydc.setColor(0x000000,0x000000);
        mydc.clear();

        // Draw the starfield
        if (starfield != null) {
            mydc.drawBitmap(0, 0, starfield);
        }

        loadgame();
System.println("onupdate state = "+state);

        if (state == 0) {
System.println("state 0 logic");
            titleXY = [SW*30/100,SH*0/100];
            titleWH = [SW*40/100,SH*20/100];
            gridsizeXY = [
                [SW*22/100,SH*20/100],
                [SW*42/100,SH*20/100],
                [SW*62/100,SH*20/100]
            ];
            difficultyXY = [
                [SW*22/100,SH*40/100],
                [SW*42/100,SH*40/100],
                [SW*62/100,SH*40/100]
            ];
            autoshieldsXY = [
                [SW*22/100,SH*60/100],
                [SW*42/100,SH*60/100],
                [SW*62/100,SH*60/100]
            ];
            buttonWH = [SW*16/100,SH*16/100];
            newgameXY = [SW*34/100,SH*80/100];
            newgameWH = [SW*32/100,SH*16/100];

            drawtitle(titleXY,titleWH);

            // Grid size selection
            drawbutton(gridsizeXY[0],buttonWH,grid>mingrid);
            tmp = gridsizeXY[0][0]+buttonWH[0]/2;
            tmp2 = gridsizeXY[0][1]+buttonWH[1]/2;
            mydc.setColor(buttonlabelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_MEDIUM,"-",center);
            drawgrid(gridsizeXY[1],buttonWH,[buttonWH[0]/grid,buttonWH[1]/grid]);
            tmp = gridsizeXY[1][0]+buttonWH[0]/2;
            tmp2 = gridsizeXY[1][1]+buttonWH[1]/2;
            mydc.setColor(labelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_TINY,grid,center);
            drawbutton(gridsizeXY[2],buttonWH,grid<maxgrid);
            tmp = gridsizeXY[2][0]+buttonWH[0]/2;
            tmp2 = gridsizeXY[2][1]+buttonWH[1]/2;
            mydc.setColor(buttonlabelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_SMALL,"+",center);

            // Difficulty size selection
            drawbutton(difficultyXY[0],buttonWH,difficulty>mindifficulty);
            tmp = difficultyXY[0][0]+buttonWH[0]/2;
            tmp2 = difficultyXY[0][1]+buttonWH[1]/2;
            mydc.setColor(buttonlabelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_MEDIUM,"-",center);
            switch (difficulty) {
                case 0:
                    drawenemy(difficultyXY[1][0], difficultyXY[1][1], buttonWH[0], buttonWH[1]);
                    break;
                case 1:
                    tmp = 70;
                    drawenemy(difficultyXY[1][0], difficultyXY[1][1], buttonWH[0]*tmp/100, buttonWH[1]*tmp/100);
                    drawenemy(difficultyXY[1][0]+buttonWH[0]*40/100, difficultyXY[1][1]+buttonWH[1]*40/100, buttonWH[0]*tmp/100, buttonWH[1]*tmp/100);
                    break;
                case 2:
                    tmp = 60;
                    drawenemy(difficultyXY[1][0], difficultyXY[1][1], buttonWH[0]*tmp/100, buttonWH[1]*tmp/100);
                    drawenemy(difficultyXY[1][0], difficultyXY[1][1]+buttonWH[1]*50/100, buttonWH[0]*tmp/100, buttonWH[1]*tmp/100);
                    drawenemy(difficultyXY[1][0]+buttonWH[0]/2, difficultyXY[1][1]+buttonWH[1]*33/100, buttonWH[0]*tmp/100, buttonWH[1]*tmp/100);
                    break;
            }
            drawbutton(difficultyXY[2],buttonWH,difficulty<maxdifficulty);
            tmp = difficultyXY[2][0]+buttonWH[0]/2;
            tmp2 = difficultyXY[2][1]+buttonWH[1]/2;
            mydc.setColor(buttonlabelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_SMALL,"+",center);

            // Auto shields selection
            tmp = autoshieldsXY[0][0]+buttonWH[0]/2;
            tmp2 = autoshieldsXY[0][1]+buttonWH[1]/2;
            mydc.setColor(labelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_XTINY,"Auto\nShields",center);
            drawship(autoshieldsXY[1][0], autoshieldsXY[1][1], buttonWH[0], buttonWH[1], autoshields);
            drawbutton(autoshieldsXY[2],buttonWH,true);
            tmp = autoshieldsXY[2][0]+buttonWH[0]/2;
            tmp2 = autoshieldsXY[2][1]+buttonWH[1]/2;
            mydc.setColor(buttonlabelcolor,-1);
            if (autoshields) { tmp3 = "On"; }
            else { tmp3 = "Off"; }
            mydc.drawText(tmp,tmp2,Graphics.FONT_XTINY,tmp3,center);

            // New game button
            drawbutton(newgameXY,newgameWH,true);
            tmp = newgameXY[0]+newgameWH[0]/2;
            tmp2 = newgameXY[1]+newgameWH[1]/2;
            mydc.setColor(buttonlabelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_XTINY,"Engage!",center);
            return;
        }

        if (state == 3) {
System.println("state 3 logic");
            // show final statistics
            // wait for "new game" button
            titleXY = [SW*30/100,SH*0/100];
            titleWH = [SW*40/100,SH*20/100];

            resultsXY = [SW/2,SH*22/100];

            statsX = [SW*10/100,SW*75/100];
            statsY = [SH*33/100,SH*42/100,SH*51/100,SH*60/100,SH*69/100];
            statsgX = SW*80/100;
            statsWH = [SW*10/100,SH*10/100];

            if (Toybox.WatchUi has :CustomMenu) {
                newgameXY = [SW*25/100,SH*77/100];
                newgameWH = [SW*25/100,SH*16/100];
                logXY = [SW*50/100,SH*77/100];
                logWH = [SW*25/100,SH*16/100];
            } else {
                logXY = [SW*25/100,SH*100/100];     // off screen
                logWH = [SW*25/100,SH*16/100];
                newgameXY = [SW*34/100,SH*77/100];
                newgameWH = [SW*32/100,SH*16/100];
            }


            drawtitle(titleXY,titleWH);

            // Final results
            if (enemies == 0) {
                mydc.setColor(wincolor,-1);
                mydc.drawText(resultsXY[0],resultsXY[1],Graphics.FONT_TINY,"Success!",center);
            } else if (days > 0) {
                mydc.setColor(shieldcolor,-1);
                mydc.drawText(resultsXY[0],resultsXY[1],Graphics.FONT_TINY,"Resign",center);
            } else {
                mydc.setColor(losecolor,-1);
                mydc.drawText(resultsXY[0],resultsXY[1],Graphics.FONT_TINY,"Defeat",center);
            }

            drawenemy(statsgX,statsY[0]-statsWH[1]/2,statsWH[0],statsWH[1]);
            drawclock(statsgX,statsY[1]-statsWH[1]/2,statsWH[0],statsWH[1]);
            drawtorp([statsgX,statsY[2]-statsWH[1]/2],statsWH,true);
            drawship(statsgX,statsY[3]-statsWH[1]/2,statsWH[0],statsWH[1],false);
            drawbase(statsgX,statsY[4]-statsWH[1]/2,statsWH[0],statsWH[1]);

            mydc.setColor(labelcolor,-1);
            mydc.drawText(statsX[0],statsY[0],Graphics.FONT_XTINY,"Destroyed:",left);
            mydc.drawText(statsX[0],statsY[1],Graphics.FONT_XTINY,"Days:",left);
            mydc.drawText(statsX[0],statsY[2],Graphics.FONT_XTINY,"Damage:",left);
            mydc.drawText(statsX[0],statsY[3],Graphics.FONT_XTINY,"Received:",left);
            mydc.drawText(statsX[0],statsY[4],Graphics.FONT_XTINY,"Dockings:",left);

            mydc.drawText(statsX[1],statsY[0],Graphics.FONT_XTINY,(maxenemies-enemies)+"/"+maxenemies,right);
            mydc.drawText(statsX[1],statsY[1],Graphics.FONT_XTINY,(maxdays-days)+"/"+maxdays,right);
            mydc.drawText(statsX[1],statsY[2],Graphics.FONT_XTINY,commas(ddealt.toNumber()),right);
            mydc.drawText(statsX[1],statsY[3],Graphics.FONT_XTINY,commas(dtaken.toNumber()),right);
            mydc.drawText(statsX[1],statsY[4],Graphics.FONT_XTINY,docks,right);

            // Log button
            drawbutton(logXY,logWH,true);
            tmp = logXY[0]+logWH[0]/2;
            tmp2 = logXY[1]+logWH[1]/2;
            mydc.setColor(buttonlabelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_XTINY,"Log",center);

            // New game button
            drawbutton(newgameXY,newgameWH,true);
            tmp = newgameXY[0]+newgameWH[0]/2;
            tmp2 = newgameXY[1]+newgameWH[1]/2;
            mydc.setColor(buttonlabelcolor,-1);
            mydc.drawText(tmp,tmp2,Graphics.FONT_XTINY,"New",center);
            return;
        }

        bigXY = [SW*20/100,SH*10/100];
        bigWH = [SW*60/100,SH*60/100];
        big1WH = [bigWH[0]/grid,bigWH[1]/grid];

        titleXY = [bigXY[0]+bigWH[0]/2, bigXY[1]/2];

        smallXY = [SW*20/100,SH*70/100];
        smallWH = [SW*20/100,SH*20/100];
        small1WH = [smallWH[0]/grid,smallWH[1]/grid];

        infoXY = [SW*40/100,SH*70/100];
        infoWH = [SW*40/100,SH*20/100];
        logXY = [SW*10/100,SH*90/100];
        logWH = [SW*80/100,SH*10/100];
        msgXY = [SW/2,SH*94/100];

        torpsXY = [SW*0/100,SH*20/100];
        torpsWH = [SW*17/100,SH*60/100];

        energyXY = [SW*82/100,SH*20/100];
        energyWH = [SW*10/100,SH*50/100];

System.println("state 1/2 logic");
        // Draw the main screen grids
        thisQuad = quad[ship[0]][ship[1]];
        drawgrid(bigXY,bigWH,big1WH);
        drawgrid(smallXY,smallWH,small1WH);
        mydc.setPenWidth(1);
        mydc.setColor(gridcolor1,-1);
        mydc.drawRectangle(infoXY[0], infoXY[1], infoWH[0], infoWH[1]);

        // Draw torpedo status on left (3 then 7)
        tmp = torpsWH[1]/7;
        tmp2 = torpsXY[1];
        tmp3 = torpsXY[0]+torpsWH[0]/2;
        for (var i=6;i>=0;i--) {
            drawtorp([tmp3,tmp2+i*tmp],[tmp,tmp],torps>i+3);
        }
        tmp2 = torpsXY[1]+tmp*2;
        tmp3 = torpsXY[0];
        for (var i=2;i>=0;i--) {
            drawtorp([tmp3,tmp2+i*tmp],[tmp,tmp],torps>i);
        }

        // Draw energy / shield status on right (vertical bar with line for shield)
        mydc.setColor(shieldcolor,-1);
        tmp = energyWH[1]*shields/maxenergy;
        mydc.fillRectangle(energyXY[0],energyXY[1]+energyWH[1]-tmp,energyWH[0],tmp);
        mydc.setColor(0x000000,-1);
        tmp2 = energyWH[0]*10/100;
        mydc.fillRectangle(energyXY[0]+tmp2,energyXY[1]+energyWH[1]-tmp,energyWH[0]-tmp2*2,tmp);
        tmp = energyWH[1]*energy/maxenergy;
        tmp2 = energyWH[0]*20/100;
        mydc.setColor(unknowncolor,-1);
        mydc.fillRectangle(energyXY[0]+tmp2,energyXY[1],energyWH[0]-tmp2*2,energyWH[1]);
        mydc.setColor(energycolor,-1);
        mydc.fillRectangle(energyXY[0]+tmp2,energyXY[1]+energyWH[1]-tmp,energyWH[0]-tmp2*2,tmp);
        drawship(energyXY[0],energyXY[1]+energyWH[1],energyWH[0],energyWH[0],shields>0);

        // Draw action buttons and highlight action destination
        if (action == null) { settingshields = 0; }
        else if (!action.equals("S")) { settingshields = 0; }
        if (action != null and !firing and !traveling and !destroying) {
            switch (action) {
                case "I":
                    drawmovebutton(true);
                    mydc.setColor(movecolor,-1);
                    break;
                case "W":
                    drawmovebutton(health[2]>0);
                    mydc.setColor(movecolor,-1);
                    break;
                case "A":
                    drawattackbuttons();
                    mydc.setColor(attackcolor,-1);
                    break;
                case "P":
                    drawphaserbuttons();
                    mydc.setColor(attackcolor,-1);
                    break;
                case "T":
                    drawtorpbuttons();
                    mydc.setColor(attackcolor,-1);
                    break;
                case "D":
                    drawdockbutton();
                    mydc.setColor(dockcolor,-1);
                    break;
                case "S":
                    drawshieldbuttons();
                    actionXY = null;
                    if (settingshields < 2) { settingshields++; }
                    break;
                case "R":
                    drawrepairbutton();
                    actionXY = null;
                    break;
                case "C":
                    drawresignbutton();
                    actionXY = null;
                    break;
            }
            if (actionXY != null) {
                mydc.setPenWidth(1);
                mydc.drawRectangle(bigXY[0]+actionXY[0]*big1WH[0], bigXY[1]+actionXY[1]*big1WH[1], big1WH[0], big1WH[1]);
            }
        } else {
            // Info area has days left, enemies left, health of engines, torps, phasers
            for (var i=0;i<health.size();i++) {
                tmp3 = health[i];
                tmp2 = infoWH[0]/6;
                tmp = infoWH[1]*65/100*tmp3/maxhealth;
                if (tmp3 == 0) { mydc.setColor(Graphics.COLOR_RED,-1); }
                else { mydc.setColor(unknowncolor,-1); }
                mydc.fillRectangle(infoXY[0]+i*tmp2+tmp2*10/100, infoXY[1]+1, tmp2*80/100, infoWH[1]*65/100);
                mydc.setColor(Graphics.COLOR_GREEN,-1);
                mydc.fillRectangle(infoXY[0]+i*tmp2+tmp2*10/100, infoXY[1]+infoWH[1]*65/100-tmp+1, tmp2*80/100, tmp);
                switch (i) {
                    case 0:
                        // torp health
                        drawtorp([infoXY[0]+i*tmp2+tmp2*10/100, infoXY[1]+infoWH[1]*70/100], [tmp2*80/100, tmp2*80/100], tmp3>0);
                        break;
                    case 1:
                        // phaser health
                        drawphaser([infoXY[0]+i*tmp2+tmp2*15/100, infoXY[1]+infoWH[1]*90/100], [infoXY[0]+i*tmp2+tmp2*75/100, infoXY[1]+infoWH[1]*75/100], tmp3>0, false);
                        break;
                    case 2:
                        // engine health
                        drawengine([infoXY[0]+i*tmp2+tmp2*10/100, infoXY[1]+infoWH[1]*70/100], [tmp2*80/100, tmp2*80/100], tmp3>0);
                        break;
                }
            }

            mydc.setPenWidth(1);
            mydc.setColor(gridcolor1,-1);
            mydc.drawLine(infoXY[0]+infoWH[0]/2,infoXY[1],infoXY[0]+infoWH[0]/2,infoXY[1]+infoWH[1]);

            tmp = infoWH[0]*5/100;
            tmp2 = infoWH[1];
            tmp3 = Graphics.FONT_XTINY;
            mydc.setColor(labelcolor,-1);
            drawclock(infoXY[0]+infoWH[0]/2,infoXY[1]+tmp2*5/100,infoWH[0]/4,infoWH[1]/2);
            mydc.drawText(infoXY[0]+infoWH[0]-tmp,infoXY[1]+tmp2*30/100,tmp3,days,right);
            drawenemy(infoXY[0]+infoWH[0]/2,infoXY[1]+infoWH[1]/2,infoWH[0]/4,infoWH[1]/2);
System.println("Values:");
System.println(infoXY[0]);
System.println(infoWH[0]);
System.println(tmp);
System.println(tmp2);
            mydc.drawText(infoXY[0]+infoWH[0]-tmp,infoXY[1]+tmp2*70/100,tmp3,enemies,right);
        }

        switch (disp) {
            case "S":
                mydc.setColor(labelcolor,-1);
                mydc.drawText(titleXY[0], titleXY[1], Graphics.FONT_XTINY, "Sector", center);

                // Highlight current quad
                mydc.setColor(selectcolor,-1);
                mydc.setPenWidth(1);
                mydc.drawRectangle(smallXY[0]+ship[0]*small1WH[0], smallXY[1]+ship[1]*small1WH[1], small1WH[0], small1WH[1]);

                // Fill in sector and quad details
System.println("Calling drawItem() with destroying = "+destroying);
                for (var i=0;i<grid;i++) {
                    for (var j=0;j<grid;j++) {
                        drawItem(sect[i][j],[bigXY[0]+i*big1WH[0],bigXY[1]+j*big1WH[1]],big1WH);
                        if (scanned[i][j]) {
                            drawIndicators(quad[i][j],[smallXY[0]+i*small1WH[0],smallXY[1]+j*small1WH[1]],small1WH);
                        } else {
                            mydc.setColor(unknowncolor,-1);
                            mydc.fillRectangle(smallXY[0]+i*small1WH[0]+1, smallXY[1]+j*small1WH[1]+1, small1WH[0]-2, small1WH[1]-2);
                        }
                    }
                }
                break;
            case "Q":
                mydc.setColor(labelcolor,-1);
                mydc.drawText(titleXY[0], titleXY[1], Graphics.FONT_XTINY, "Quadrant", center);

                // Highlight current quad
                mydc.setColor(selectcolor,-1);
                mydc.setPenWidth(1);
                mydc.drawRectangle(bigXY[0]+ship[0]*big1WH[0], bigXY[1]+ship[1]*big1WH[1], big1WH[0], big1WH[1]);

                // Fill in sector and quad details
                for (var i=0;i<grid;i++) {
                    for (var j=0;j<grid;j++) {
                        drawItem2(sect[i][j],[smallXY[0]+i*small1WH[0],smallXY[1]+j*small1WH[1]],small1WH);
                        if (scanned[i][j]) {
                            drawIndicators(quad[i][j],[bigXY[0]+i*big1WH[0],bigXY[1]+j*big1WH[1]],big1WH);
                        } else {
                            mydc.setColor(unknowncolor,-1);
                            mydc.fillRectangle(bigXY[0]+i*big1WH[0]+1, bigXY[1]+j*big1WH[1]+1, big1WH[0]-2, big1WH[1]-2);
                        }
                    }
                }
                break;
        }

        // Red alert?
        if (thisQuad[0]>0 and disp.equals("S")) {
            mydc.setPenWidth(1);
            mydc.setColor(alertcolor,-1);
            mydc.drawRectangle(bigXY[0], bigXY[1], bigWH[0], bigWH[1]);
        }

        if (state == 2) {
            if (destroying) {
                tmp = gridXY(destroyXY);
                destroyenemy(tmp[0],tmp[1],big1WH[0],big1WH[1]);
                deseg++;
                if (deseg > 10) { destroying = false; }
                else { wait = 100; }
            }
            if (action != null and (!destroying or traveling)) {
                switch (action) {
                    case "W":
                        if (traveling) {
                            tmp = path[seg];
                            drawship(tmp[0],tmp[1],big1WH[0],big1WH[1],false);
                            seg++;
                            if (seg >= path.size()) {
                                var l = dist(ship,actionXY);
                                tmp = l*(maxhealth*1.0-health[2])/maxhealth;
                                l = (l+tmp).toNumber();
                                days -= l;
                                if (l == 1) {
                                    msg = "Warp 1 day";
                                } else {
                                    msg = "Warp "+l+" days";
                                }
                                addlog(msg);
                                ship[0] = actionXY[0];
                                ship[1] = actionXY[1];
                                randsect();
                                LRS();
                                disp = "S";
                                traveling = false;
                                action = null;
                                justwarped = true;
                            } else {
                                wait = 100;
                            }
                        }
                        break;
                    case "I":
                        if (traveling) {
                            tmp = path[seg];
                            drawship(tmp[0],tmp[1],big1WH[0],big1WH[1],false);
                            seg++;
                            tmp2 = XYgrid(tmp);
                            tmp3 = -1;
                            if (tmp2[0] >= 0 and tmp2[0] < grid and tmp2[1] >= 0 and tmp2[1] < grid) {
                                // still within the grid
                                if (tmp2[2] <= 85) {
                                    // close enough to the center of a sector grid
                                    tmp3 = sect[tmp2[0]][tmp2[1]];
                                    if (tmp3 == 3) { tmp3 = null; }  // our ship doesn't count
                                } else {
                                    tmp3 = null;
                                }
                            }
                            if (tmp3 != null) {
                                switch (tmp3) {
                                    case 0:
                                        // Ramming an enemy
                                        // tmp2 is 0 to 85, indicating how close we are (0 = close)
                                        // damage enemy and ourselves from 400 to 800
                                        if (destroying) {
                                            if (destroyXY[0] == tmp2[0] and destroyXY[1] == tmp2[1]) {
                                                // Same enemy
                                                break;
                                            }
                                        }
                                        addlog("Rammed Enemy");
                                        tmp = 400 + Math.rand() % ((100-tmp2[2])*4).toNumber();
                                        damageenemy(tmp2,tmp);
                                        damageship(tmp);
                                        break;
                                    case 1:
                                        // Ramming a base
                                        // tmp2 is 0 to 85, indicating how close we are (0 = close)
                                        // damage ourselves somefrom 100 to 200
                                        addlog("Rammed Base");
                                        tmp = 100 + Math.rand() % (100-tmp2[2]).toNumber();
                                        damageship(tmp);
                                        break;
                                    case 2:
                                        // Hitting a star
                                        // tmp2 is 0 to 85, indicating how close we are (0 = close)
                                        // damage ourselves from 100 to 400
                                        addlog("Rammed a Star");
                                        tmp = 100 + Math.rand() % (100-tmp2[2]*4).toNumber();
                                        damageship(tmp);
                                        break;
                                }
                            }
                            if (seg >= path.size()) {
                                sect[actionXY[0]][actionXY[1]] = 3;
                                traveling = false;
                                action = null;
                            } else {
                                wait = 100;
                            }
                        }
                        break;
                    case "T":
                        if (firing) {
                            tmp3 = -1;
                            if (seg < path.size()) {
                                tmp = path[seg];
                                seg++;
                                tmp2 = XYgrid(tmp);
                                if (tmp2[0] >= 0 and tmp2[0] < grid and tmp2[1] >= 0 and tmp2[1] < grid) {
                                    // still within the grid
                                    if (tmp2[2] <= 85) {
                                        // close enough to the center of a sector grid
                                        tmp3 = sect[tmp2[0]][tmp2[1]];
                                        if (tmp3 == 3) { tmp3 = null; }  // our ship doesn't count
                                    } else {
                                        tmp3 = null;
                                    }
                                }
                            }
                            if (tmp3 != null) {
                                switch (tmp3) {
                                    case -1:
                                        msgcolor = labelcolor;
                                        msg = "Miss!";
                                        addlog("Torpedo miss");
                                        break;
                                    case 0:
                                        // hit an enemy
                                        // damage = 200-250 (random)
                                        damageenemy([tmp2[0],tmp2[1]],200 + Math.rand() % 50);
                                        break;
                                    case 1:
                                        msgcolor = labelcolor;
                                        msg = "Hit a base!";
                                        addlog("Torpedo hit base");
                                        break;
                                    case 2:
                                        msgcolor = labelcolor;
                                        msg = "Hit a star";
                                        addlog("Torpedo hit star");
                                        break;
                                }
                                fire--;
                                if (fire == 0) {
                                    firing = false;
                                    action = null;
                                } else {
                                    firetorp(findship(),actionXY);
                                }
                                wait = 100;
                            } else {
                                tmp2 = [tmp[0]+big1WH[0]/4,tmp[1]+big1WH[1]/4];
                                drawtorp(tmp2,[big1WH[0]/2,big1WH[1]/2],true);
                                wait = 50;
                            }
                        } else {
                            firetorp(findship(),actionXY);
                        }
                        break;
                    case "P":
                        if (firing) {
                            seg++;
                            if (seg == 1) {
                                tmp = [path[0][0]+big1WH[0]/2,path[0][1]+big1WH[1]/2];
                                tmp2 = [path[1][0]+big1WH[0]/2,path[1][1]+big1WH[1]/2];
                                drawphaser(tmp,tmp2,true,false);
                                tmp2 = XYgrid(path[1]);
                                tmp3 = -1;
                                tmp3 = sect[tmp2[0]][tmp2[1]];
                                if (tmp3 == null) {
                                    msgcolor = labelcolor;
                                    msg = "Miss!";
                                    addlog("Phasers miss");
                                } else {
                                    switch (tmp3) {
                                        case 0:
                                            // hit an enemy
                                            // damage = 100 to 150 (random)
                                            // distance reduces damage by up to 40
                                            // health reduces damage by up to 40
                                            // phasers always do damage
                                            var d = 100 + Math.rand() % 50;
                                            if (d > energy-shields) { d = energy-shields; }
                                            energy -= d;
                                            var l = dist(findship(),actionXY)*40/grid;
                                            var h = 40-health[0]*40/maxhealth;
                                            d = (d - l - h).toNumber();
                                            damageenemy(actionXY,d);
                                            break;
                                        case 1:
                                            msgcolor = labelcolor;
                                            msg = "Hit a base!";
                                            addlog("Phasers hit base");
                                            break;
                                        case 2:
                                            msgcolor = labelcolor;
                                            msg = "Hit a star";
                                            addlog("Phasers hit star");
                                            break;
                                    }
                                }
                                wait = 700;
                            } else {
                                fire--;
                                if (fire == 0) {
                                    firing = false;
                                    action = null;
                                } else {
                                    firephaser(findship(),actionXY);
                                    wait = 50;
                                }
                            }
                        } else {
                            firephaser(findship(),actionXY);
                        }
                        break;
                    default:
                        action = null;
                }
            } else if(!destroying) {
                if (justwarped) {
                    justwarped = false;
                } else {
                    enemyturn();
                }
                state = 1;
            }
            savegame();
            drawmsg();
            if (wait != null) {
                timer = new Timer.Timer();
                timer.start(method(:onTimer), wait, false);
            } else {
                WatchUi.requestUpdate();
            }
        } else {
            drawmsg();
        }

    }

    function drawmsg() {
        if (msg != null) {
System.println("Displaying message: "+msg);
            mydc.setColor(msgcolor,-1);
            mydc.drawText(msgXY[0], msgXY[1], Graphics.FONT_XTINY, msg, center);
            tmp = lastmsg.add(msgwait);
            var now = new Time.Moment(Time.now().value());
            if (now.greaterThan(tmp)) {
                msg = null;
                msgcolor = labelcolor;
                lastmsg = new Time.Moment(now.value());
            }
        }
    }

    function onTimer() as Void {
        wait = null;
        WatchUi.requestUpdate();
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    function drawgrid(xy,wh,wh1) {
        mydc.setPenWidth(1);
        mydc.setColor(gridcolor1,-1);
        mydc.drawRectangle(xy[0], xy[1], wh[0], wh[1]);
        mydc.setColor(gridcolor2,-1);
        for (var i=1;i<grid;i++) {
            mydc.drawLine(xy[0]+i*wh1[0], xy[1], xy[0]+i*wh1[0], xy[1]+wh[1]);
            mydc.drawLine(xy[0], xy[1]+i*wh1[1], xy[0]+wh[0], xy[1]+i*wh1[1]);
        }
    }

    // Draw an item
    // t: 0=base, 1=enemy, 2=star, 3=ship
    function drawItem(t,xy,wh) {
        if (t == null) { return; }
        var x = xy[0];
        var y = xy[1];
        var w = wh[0];
        var h = wh[1];
        switch (t) {
            case 0:
                // Enemy
                drawenemy(x,y,w,h);
                break;
            case 1:
                // Base
                drawbase(x,y,w,h);
                break;
            case 2:
                // Star
                mydc.setColor(starcolor2,-1);
                penwidth(w/15);
                mydc.drawLine(x+w*28/100, y+h*28/100, x+w*72/100, y+h*72/100);
                mydc.drawLine(x+w*72/100, y+h*28/100, x+w*28/100, y+h*72/100);
                penwidth(w/12);
                mydc.drawLine(x+w/2, y+h*20/100, x+w/2, y+h*80/100);
                mydc.drawLine(x+w*20/100, y+h/2, x+w*80/100, y+h/2);
                mydc.setColor(starcolor1,-1);
                mydc.fillCircle(x+w/2,y+h/2,w*28/100);
                break;
            case 3:
                // Our ship
                drawship(x,y,w,h,false);
                break;
        }
    }

    function drawenemy(x,y,w,h) {
        mydc.setColor(enemycolor2,-1);
        mydc.fillRectangle(x+w*20/100, y+h*35/100, w*55/100, h*10/100);
        mydc.fillPolygon([
            [x+w*12/100,y+h*35/100],
            [x+w*45/100,y+h*35/100],
            [x+w*55/100,y+h*60/100],
            [x+w*40/100,y+h*60/100]
        ]);
        mydc.fillRectangle(x+w*40/100, y+h*60/100, w*15/100, h*10/100);
        mydc.setColor(enemycolor1,-1);
        mydc.fillEllipse(x+w*75/100, y+h*40/100, w*15/100, h*8/100);
        mydc.fillEllipse(x+w*32/100, y+h*35/100, w*20/100, h*10/100);
        mydc.fillRectangle(x+w*50/100, y+h*65/100, w*25/100, h*5/100);
    }

    function destroyenemy(x,y,w,h) {
        switch (deseg) {
            case 0:
                mydc.setColor(enemycolor2,-1);
                mydc.fillRectangle(x+w*20/100, y+h*35/100, w*55/100, h*10/100);
                mydc.fillPolygon([
                    [x+w*12/100,y+h*35/100],
                    [x+w*45/100,y+h*35/100],
                    [x+w*55/100,y+h*60/100],
                    [x+w*40/100,y+h*60/100]
                ]);
                mydc.fillRectangle(x+w*40/100, y+h*60/100, w*15/100, h*10/100);
                mydc.setColor(enemycolor1,-1);
                mydc.fillEllipse(x+w*75/100, y+h*40/100, w*15/100, h*8/100);
                mydc.fillEllipse(x+w*32/100, y+h*35/100, w*20/100, h*10/100);
                mydc.fillRectangle(x+w*50/100, y+h*65/100, w*25/100, h*5/100);

                penwidth(w*3/100);
                mydc.setColor(phasercolor1,-1);
                mydc.drawLine(x+w/2,y+h/4,x+w/2,y+h*3/4);
                mydc.drawLine(x+w/3,y+h/3,x+w*2/3,y+h*2/3);
                mydc.drawLine(x+w*2/3,y+h/3,x+w/3,y+h*2/3);
                mydc.setColor(phasercolor2,-1);
                mydc.fillCircle(x+w/2,y+h/2,w*10/100);
                break;
            case 1:
                mydc.setColor(enemycolor2,-1);
                mydc.fillRectangle(x+w*20/100, y+h*35/100, w*55/100, h*10/100);
                mydc.fillPolygon([
                    [x+w*12/100,y+h*35/100],
                    [x+w*45/100,y+h*35/100],
                    [x+w*55/100,y+h*60/100],
                    [x+w*40/100,y+h*60/100]
                ]);
                mydc.fillRectangle(x+w*40/100, y+h*60/100, w*15/100, h*10/100);
                mydc.setColor(enemycolor1,-1);
                mydc.fillEllipse(x+w*75/100, y+h*40/100, w*15/100, h*8/100);
                mydc.fillEllipse(x+w*32/100, y+h*35/100, w*20/100, h*10/100);
                mydc.fillRectangle(x+w*50/100, y+h*65/100, w*25/100, h*5/100);

                penwidth(w*6/100);
                mydc.setColor(phasercolor1,-1);
                mydc.drawLine(x+w/2,y+h/4,x+w/2,y+h*3/4);
                mydc.drawLine(x+w/3,y+h/3,x+w*2/3,y+h*2/3);
                mydc.drawLine(x+w*2/3,y+h/3,x+w/3,y+h*2/3);
                mydc.setColor(phasercolor2,-1);
                mydc.fillCircle(x+w/2,y+h/2,w*20/100);
                mydc.setColor(phasercolor1,-1);
                mydc.fillCircle(x+w/2,y+h/2,w*10/100);
                break;
            case 2:
                penwidth(w*9/100);
                mydc.setColor(phasercolor1,-1);
                mydc.drawLine(x+w/2,y+h/4,x+w/2,y+h*3/4);
                mydc.drawLine(x+w/3,y+h/3,x+w*2/3,y+h*2/3);
                mydc.drawLine(x+w*2/3,y+h/3,x+w/3,y+h*2/3);
                mydc.setColor(phasercolor2,-1);
                mydc.fillCircle(x+w/2,y+h/2,w*30/100);
                mydc.setColor(phasercolor1,-1);
                mydc.fillCircle(x+w/2,y+h/2,w*20/100);
                break;
            case 3:
                penwidth(w*12/100);
                mydc.setColor(phasercolor1,-1);
                mydc.drawLine(x+w/2,y+h/4,x+w/2,y+h*3/4);
                mydc.drawLine(x+w/3,y+h/3,x+w*2/3,y+h*2/3);
                mydc.drawLine(x+w*2/3,y+h/3,x+w/3,y+h*2/3);
                mydc.setColor(phasercolor2,-1);
                mydc.fillCircle(x+w/2,y+h/2,w*40/100);
                mydc.setColor(phasercolor1,-1);
                mydc.fillCircle(x+w/2,y+h/2,w*30/100);
                destroying = false;
                break;
        }
    }

    function drawclock(x,y,w,h) {
        mydc.setColor(labelcolor,-1);
        penwidth(w*5/100);
        mydc.drawCircle(x+w/2,y+h/2,w*35/100);
        mydc.drawLine(x+w/2,y+h/2,x+w/2,y+h*20/100);
        mydc.drawLine(x+w/2,y+h/2,x+w*70/100,y+h/2);
    }

    function drawship(x,y,w,h,s) {
        if (s) {
            mydc.setColor(shieldcolor,-1);
            penwidth(w/8);
            mydc.drawLine(x+w*36/100, y+w*41/100, x+w*58/100, y+h*68/100);
            mydc.drawLine(x+w*56/100, y+w*41/100, x+w*68/100, y+h*68/100);
            mydc.fillEllipse(x+w*30/100, y+h*45/100, w*24/100, h*10/100);
            mydc.fillRoundedRectangle(x+w*46/100, y+h*31/100, w*48/100, h*18/100, w/14);
            mydc.fillRoundedRectangle(x+w*36/100, y+h*56/100, w*48/100, h*23/100, w/10);
            mydc.setColor(0x000000,-1);
            penwidth(w/10);
            mydc.drawLine(x+w*38/100, y+w*43/100, x+w*54/100, y+h*64/100);
            mydc.drawLine(x+w*58/100, y+w*43/100, x+w*64/100, y+h*64/100);
            mydc.fillEllipse(x+w*30/100, y+h*45/100, w*22/100, h*8/100);
            mydc.fillRoundedRectangle(x+w*48/100, y+h*33/100, w*44/100, h*14/100, w/15);
            mydc.fillRoundedRectangle(x+w*38/100, y+h*58/100, w*44/100, h*19/100, w/11);
        }
        mydc.setColor(shipcolor2,-1);
        penwidth(w/12);
        mydc.drawLine(x+w*40/100, y+w*45/100, x+w*50/100, y+h*60/100);
        mydc.drawLine(x+w*60/100, y+w*45/100, x+w*60/100, y+h*60/100);
        mydc.setColor(shipcolor1,-1);
        mydc.fillEllipse(x+w*30/100, y+h*45/100, w*20/100, h*6/100);
        mydc.fillRoundedRectangle(x+w*50/100, y+h*35/100, w*40/100, h*10/100, w/16);
        mydc.fillRoundedRectangle(x+w*40/100, y+h*60/100, w*40/100, h*15/100, w/12);
    }

    function drawbase(x,y,w,h) {
        mydc.setColor(basecolor2,-1);
        mydc.fillEllipse(x+w/2, y+h/2, w*10/100, h*40/100);
        mydc.setColor(basecolor1,-1);
        mydc.fillEllipse(x+w/2, y+h*35/100, w*40/100, h/8);
        mydc.fillEllipse(x+w/2, y+h*50/100, w*30/100, h/8);
    }

    function drawItem2(t,xy,wh) {
        if (t == null) { return; }
        var x = xy[0]+1;
        var y = xy[1]+1;
        var w = wh[0]-2;
        var h = wh[1]-2;
        switch (t) {
            case 0:
                // Enemy
                mydc.setColor(enemycolor1,-1);
                break;
            case 1:
                // Base
                mydc.setColor(basecolor1,-1);
                break;
            case 2:
                // Star
                mydc.setColor(starcolor2,-1);
                break;
            case 3:
                // Our ship
                mydc.setColor(shipcolor1,-1);
                break;
            default:
                return;
        }
        mydc.fillRectangle(x, y, w, h);
    }

    // Draw quadrant indicators
    // q: [enemies,bases,stars]
    function drawIndicators(q,xy,wh) {
        var x1 = xy[0]+1;
        var y1 = xy[1]+1;
        var w = wh[0]/2-2;
        var h = wh[1]/2-2;
        var x2 = xy[0]+wh[0]-w-1;
        var y2 = xy[1]+wh[1]-h-1;
        var e = q[0];
        var b = q[1];
        mydc.setColor(enemycolor1,-1);
        switch (e) {
            case 3:
                mydc.fillRectangle(x1,y2,w,h);
            case 2:
                mydc.fillRectangle(x2,y1,w,h);
            case 1:
                mydc.fillRectangle(x1,y1,w,h);
        }
        if (b > 0) {
            mydc.setColor(basecolor1,-1);
            mydc.fillRectangle(x2,y2,w,h);
        }
    }

    function draw1button(v) {
        drawbutton([infoXY[0]+1,infoXY[1]+1],[infoWH[0]-2,infoWH[1]-2],v);
    }

    function draw2buttons(v1,v2) {
        drawbutton([infoXY[0]+1,infoXY[1]+1],[infoWH[0]/2-2,infoWH[1]-2],v1);
        drawbutton([infoXY[0]+infoWH[0]/2+1,infoXY[1]+1],[infoWH[0]/2-2,infoWH[1]-2],v2);
    }

    function drawbutton(xy,wh,v) {
        if (v) {
            for (var i=1;i<so;i++) {
                mydc.setColor(buttoncolord,-1);
                mydc.fillRectangle(xy[0]+i,xy[1]+i,wh[0]-i,wh[1]-i);
                mydc.setColor(buttoncolorl,-1);
                mydc.fillRectangle(xy[0],xy[1],wh[0]-i*2,wh[1]-i*2);
            }
            mydc.setColor(buttoncolor,-1);
            mydc.fillRectangle(xy[0]+so,xy[1]+so,wh[0]-so*2,wh[1]-so*2);
        } else {
            mydc.setColor(brokencolor,-1);
            mydc.fillRectangle(xy[0],xy[1],wh[0],wh[1]);            
        }
    }

    function commas(whole) {
        if (whole == 0) { return "0"; }
        var digits = [];
        var count = 0;
        while (whole != 0) {
            var digit = (whole % 10).toString();
            whole /= 10;
            if (count == 3) {
                digits.add(",");
                count = 0;
            }
            ++count;
            digits.add(digit);
        }
        digits = digits.reverse();
        whole = "";
        for (var i = 0; i < digits.size(); ++i) {
            whole += digits[i];
        }
        return whole;
    }

    function drawtitle(xy,wh) {
        mydc.setColor(titlecolor,-1);
        mydc.drawText(xy[0]+wh[0]*50/100, xy[1]+wh[1]*60/100, Graphics.FONT_TINY, "SPACE TREK", center);
//        mydc.drawText(xy[0]+wh[0]*58/100, xy[1]+wh[1]*40/100, Graphics.FONT_TINY, "SPACE", right);
//        mydc.drawText(xy[0]+wh[0]*58/100, xy[1]+wh[1]*65/100, Graphics.FONT_TINY, "TREK", left);
    }

    function drawmovebutton(v) {
        draw1button(v);
        tmp = infoWH[0]/2;
        tmp2 = infoXY[0]+(infoWH[0]-tmp)/2;
        tmp3 = infoXY[1]+(infoWH[1]-tmp)/2;
        drawship(tmp2-tmp*20/100,tmp3,tmp,tmp,false);
        mydc.setColor(movecolor,-1);
        tmp3 = infoWH[1]/7;
        penwidth(tmp*4/100);
        mydc.drawLine(tmp2+tmp*80/100, infoXY[1]+tmp3*3, tmp2+tmp, infoXY[1]+tmp3*3);
        mydc.drawLine(tmp2+tmp*70/100, infoXY[1]+tmp3*4, tmp2+tmp*110/100, infoXY[1]+tmp3*4);
        mydc.drawLine(tmp2+tmp*70/100, infoXY[1]+tmp3*5, tmp2+tmp, infoXY[1]+tmp3*5);
        if (v) {
            msgcolor = labelcolor;
            msg = "Engage?";
        } else {
            msgcolor = brokencolor;
            msg = "BROKEN!";
        }
    }

    function drawrepairbutton() {
        draw1button(true);
        tmp = infoWH[0]/2;
        tmp2 = tmp*35/100;
        tmp3 = infoWH[1]*15/100;
        drawtorp([infoXY[0]+tmp3,infoXY[1]+tmp3], [tmp*70/100,tmp*70/100], true);
        drawphaser([infoXY[0]+tmp2*2+tmp3,infoXY[1]+infoWH[1]-tmp3*2],[infoXY[0]+tmp2*3+tmp3,infoXY[1]+tmp3*2],true,false);
        drawengine([infoXY[0]+tmp2*3+tmp3,infoXY[1]+tmp3], [tmp*70/100,tmp*70/100], true);
        msgcolor = labelcolor;
        msg = "Repair?";
    }

    function drawresignbutton() {
        draw1button(true);
        mydc.setColor(buttonlabelcolor,-1);
        mydc.drawText(infoXY[0]+infoWH[0]/2,infoXY[1]+infoWH[1]/2,Graphics.FONT_TINY,"Resign",center);
        msgcolor = labelcolor;
        msg = "Resign?";
    }

    function drawdockbutton() {
        draw1button(true);
        tmp = infoWH[0]/2;
        tmp2 = tmp*10/100;
        drawbase(infoXY[0]+tmp2,infoXY[1],tmp,infoWH[1]);
        drawship(infoXY[0]+tmp-tmp2,infoXY[1],tmp,infoWH[1],false);
        msgcolor = labelcolor;
        msg = "Dock?";
    }

    function drawattackbuttons() {
        // If not enough energy for even short burst phasers, dim left button
        // If no torpedoes left, dim right button
        draw2buttons(health[1] > 0 and energy-shields > 0, health[0] > 0 and torps > 0);
        tmp = infoWH[0]/2;
        tmp2 = tmp*30/100;
        tmp3 = infoWH[1]*30/100;
        drawphaser([infoXY[0]+tmp2,infoXY[1]+infoWH[1]-tmp3],[infoXY[0]+tmp-tmp2,infoXY[1]+tmp3], energy-shields > 0, false);
        tmp = infoWH[0]/2;
        tmp2 = tmp*30/100;
        tmp3 = infoWH[1]*30/100;
        drawtorp([infoXY[0]+tmp+tmp2,infoXY[1]+tmp3], [tmp*40/100,infoWH[1]*40/100], torps > 0);
        if (health[0] == 0 and health[1] == 0) {
            msgcolor = brokencolor;
            msg = "BROKEN!";
        } else {
            tmp = esect[actionXY[0]][actionXY[1]];
            tmp = tmp*100/enemyenergy;
            if (tmp == 0) { tmp = 1; }
            msgcolor = labelcolor;
            msg = "Enemy "+tmp+"%";
        }
    }

    function drawphaserbuttons() {
        draw2buttons(health[1]>0 and energy-shields > 0,health[1]>0 and energy-shields >= p2energy);
        tmp = infoWH[0]/2;
        tmp2 = tmp*30/100;
        tmp3 = infoWH[1]*30/100;
        drawphaser([infoXY[0]+tmp2,infoXY[1]+infoWH[1]-tmp3],[infoXY[0]+tmp-tmp2,infoXY[1]+tmp3],energy-shields>0,false);
        drawphaser([infoXY[0]+tmp+tmp2-tmp/6,infoXY[1]+infoWH[1]-tmp3],[infoXY[0]+tmp*2-tmp2-tmp/6,infoXY[1]+tmp3],energy-shields>=p2energy,false);
        drawphaser([infoXY[0]+tmp+tmp2+tmp/6,infoXY[1]+infoWH[1]-tmp3],[infoXY[0]+tmp*2-tmp2+tmp/6,infoXY[1]+tmp3],energy-shields>=p2energy,false);
        if (health[1]>0) {
            msgcolor = labelcolor;
            msg = "Fire 1 or 2?";
        } else {
            msgcolor = brokencolor;
            msg = "BROKEN!";
        }
    }

    function drawtorpbuttons() {
        draw2buttons(health[0]>0 and torps>0, health[0]>0 and torps>1);
        tmp = infoWH[0]/2;
        tmp2 = tmp*30/100;
        tmp3 = infoWH[1]*30/100;
        drawtorp([infoXY[0]+tmp2,infoXY[1]+tmp3], [tmp*40/100,infoWH[1]*40/100], torps>0);
        drawtorp([infoXY[0]+tmp+tmp2-tmp/6,infoXY[1]+tmp3], [tmp*40/100,infoWH[1]*40/100], torps>1);
        drawtorp([infoXY[0]+tmp+tmp2+tmp/6,infoXY[1]+tmp3], [tmp*40/100,infoWH[1]*40/100], torps>1);
        if (health[0]>0) {
            msgcolor = labelcolor;
            msg = "Fire 1 or 2?";
        } else {
            msgcolor = brokencolor;
            msg = "BROKEN!";
        }
    }

    function drawshieldbuttons() {
        // gray out based on current shields vs. available energy
        draw2buttons(shields>0,shields<energy);
        mydc.setColor(buttonlabelcolor,-1);
        mydc.drawText(infoXY[0]+infoWH[0]/4,infoXY[1]+infoWH[1]/2,Graphics.FONT_MEDIUM,"-",center);
        mydc.drawText(infoXY[0]+infoWH[0]*3/4,infoXY[1]+infoWH[1]/2,Graphics.FONT_SMALL,"+",center);
        msgcolor = labelcolor;
        tmp = shields*100/energy;
        msg = "Shields "+tmp+"%";
        addlog(msg);
    }

}

function randsect() {
    thisQuad = quad[ship[0]][ship[1]];
    // initialize sector
    sect = [];
    esect = [];
    for (var i=0;i<grid;i++) {
        tmp = [];
        tmp2 = [];
        for (var j=0;j<grid;j++) {
            tmp.add(null);
            tmp2.add(null);
        }
        sect.add(tmp);
        esect.add(tmp2);
    }
    // randomly place sector elements (stars, then bases, then enemies)
    for (var i=2;i>=0;i--) {
        tmp3 = thisQuad[i];
        while (tmp3 > 0) {
            tmp = Math.rand() % grid;
            tmp2 = Math.rand() % grid;
            if (safespace(tmp,tmp2)) {
                sect[tmp][tmp2] = i;
                if (i == 0) {esect[tmp][tmp2] = enemyenergy; }
                tmp3--;
            }
        }
    }
    // randomly place our ship
    tmp3 = 1;
    while (tmp3 > 0) {
        tmp = Math.rand() % grid;
        tmp2 = Math.rand() % grid;
        if (safespace(tmp,tmp2)) {
            sect[tmp][tmp2] = 3;
            tmp3--;
        }
    }
    // automatic shields
    if (autoshields and shields < energy/2 and thisQuad[0] > 0) {
        shields = energy/2;
        msg = "Sheilds Up!";
        addlog("Shields 50%");
    }
}

function safespace(x,y) {
    if (sect[x][y] != null) { return false; }
    var spaces = 0;
    for (var i=x-1;i<x+2;i++) {
        for (var j=y-1;j<y+2;j++) {
            if (i>=0 and i<grid and j>=0 and j<grid) {
                if (sect[i][j] == null) { spaces++; }
            }
        }
    }
    if (spaces >= 2) { return true; }
    return false;
}

function LRS() {
    for (var i=ship[0]-1;i<ship[0]+2;i++) {
        for (var j=ship[1]-1;j<ship[1]+2;j++) {
            if (i>=0 and i<grid and j>=0 and j<grid) {
                scanned[i][j] = true;
            }
        }
    }
}

function drawtorp(xy,wh,a) {
    var x = xy[0];
    var y = xy[1];
    var w = wh[0];
    var h = wh[1];
    if (a) { mydc.setColor(torpcolor2,-1); }
    else { mydc.setColor(unknowncolor,-1); }
    penwidth(w/20);
    mydc.drawLine(x+w*28/100, y+h*28/100, x+w*72/100, y+h*72/100);
    mydc.drawLine(x+w*72/100, y+h*28/100, x+w*28/100, y+h*72/100);
    penwidth(w/15);
    mydc.drawLine(x+w/2, y+h*20/100, x+w/2, y+h*80/100);
    mydc.drawLine(x+w*20/100, y+h/2, x+w*80/100, y+h/2);
    if (a) { mydc.setColor(torpcolor1,-1); }
    else { mydc.setColor(unknowncolor,-1); }
    mydc.fillCircle(x+w/2,y+h/2,w*15/100);
}

function drawphaser(xy1,xy2,a,e) {
    var x1 = xy1[0];
    var y1 = xy1[1];
    var x2 = xy2[0];
    var y2 = xy2[1];
    var x3,y3;
    var c1,c2;
    var ratio;
    var c = new [4];
    var s = 8;
    var l = dist(xy1,xy2);
    var w = 4;
    if (a) {
        if (e) {
            c1 = splitcolor(disruptcolor1);
            c2 = splitcolor(disruptcolor2);
        } else {
            c1 = splitcolor(phasercolor1);
            c2 = splitcolor(phasercolor2);
        }
    } else {
        c1 = splitcolor(unknowncolor);
        c2 = splitcolor(unknowncolor);
    }
    penwidth(1);
    mydc.setColor(combinecolor(c1),-1);
    mydc.drawLine(x1,y1,x2,y2);
    for (var i=-1*s;i<s;i++) {
        ratio = (i+s+1*1.0)/(s*2);
        for (var j=0;j<3;j++) {
            c[j] = (c1[j]*(1-ratio)+c2[j]*ratio).toNumber();
        }
        x3 = (x1*(1-ratio)+x2*ratio).toNumber();
        y3 = (y1*(1-ratio)+y2*ratio).toNumber();
        penwidth(w*ratio);
        mydc.setColor(combinecolor(c),-1);
        mydc.drawLine(x3,y3,x2,y2);
    }
}

function splitcolor(c) {
    return [c/65536,c/256%256,c%256];
}
function combinecolor(c) {
    return c[0]*65536+c[1]*256+c[2];
}

function drawengine(xy,wh,a) {
    var x = xy[0];
    var y = xy[1];
    var w = wh[0];
    var h = wh[1];
    if (a) { mydc.setColor(enginecolor1,-1); }
    else { mydc.setColor(unknowncolor,-1); }
    mydc.fillRectangle(x+w*30/100, y+h*10/100, w*40/100, h*80/100);
    if (a) { mydc.setColor(enginecolor2,-1); }
    else { mydc.setColor(unknowncolor,-1); }
    penwidth(w/20);
    mydc.drawRectangle(x+w*30/100, y+h*10/100, w*40/100, h*80/100);
    mydc.fillPolygon([
        [x+w*20/100, y+h*10/100],
        [x+w*80/100, y+h*10/100],
        [x+w*70/100, y+h*20/100],
        [x+w*30/100, y+h*20/100]
    ]);
    penwidth(w/20);
    mydc.drawLine(x+w*28/100, y+h*32/100, x+w*72/100, y+h*32/100);
    mydc.drawLine(x+w*28/100, y+h*55/100, x+w*72/100, y+h*55/100);
    mydc.drawLine(x+w*28/100, y+h*65/100, x+w*72/100, y+h*65/100);
    mydc.fillRectangle(x+w*25/100, y+h*85/100, w*50/100, h*10/100);
}

function firetorp(xy1,xy2) {
    torps--;
    firing = true;
    tmp = gridXY(xy1);
    tmp2 = gridXY(xy2);
    // Calculate variation in destination based on distance and torp damage
    // Grid-length shots can be off by as much as half a grid in any direction
    // Damage can vary the shot by up to a full grid in any direction
    var l = dist(xy1,xy2);
    tmp3 = big1WH[0];
    tmp3 = (l*tmp3/grid*2/3 + (maxhealth-health[0])*tmp3/maxhealth).toNumber();
    tmp2[0] = tmp2[0] + tmp3 - Math.rand() % (tmp3*2);
    tmp2[1] = tmp2[1] + tmp3 - Math.rand() % (tmp3*2);
    path = [];
    l = l * 2;  // More segments = smoother animation and better hit detection
    var x = (tmp2[0]-tmp[0])/l;
    var y = (tmp2[1]-tmp[1])/l;
    for (var i=0;i<grid*3;i++) {
        path.add([tmp[0]+i*x,tmp[1]+i*y]);
    }
System.println("path: "+path);
    seg = 0;
}

function firephaser(xy1,xy2) {
    firing = true;
    tmp = gridXY(xy1);
    tmp2 = gridXY(xy2);
    var l = dist(xy1,xy2);
    path = [];
    l = l * 2;  // More segments = better hit detection
    var x = (tmp2[0]-tmp[0])/l;
    var y = (tmp2[1]-tmp[1])/l;
    path.add(tmp);
    tmp4 = tmp2;
System.println("Phaser path:");
System.println(tmp);
    for (var i=0;i<grid*3;i++) {
        tmp2 = [tmp[0]+i*x,tmp[1]+i*y];
        tmp3 = XYgrid(tmp2);
System.println("sect: "+tmp3);
        tmp5 = -1;
        if (tmp3[0] >= 0 and tmp3[0] < grid and tmp3[1] >= 0 and tmp3[1] < grid) {
            // still within the grid
//            tmp4 = gridXY(tmp3);
            tmp4 = tmp2;
            if (tmp3[2] <= 85) {
                // close enough to the center of a sector grid
                tmp5 = sect[tmp3[0]][tmp3[1]];
System.println("sect contains "+tmp5);
                if (tmp5 == 3) { tmp5 = null; }  // our ship doesn't count
            } else {
                tmp5 = null;
            }
        }
        if (tmp5 != null) {
            break;
        }
    }
System.println(tmp4);
System.println("Done");
    path.add(tmp4);
    seg = 0;
}

function damageenemy(xy,d) {
    ddealt += d;
    var e = esect[xy[0]][xy[1]];
    if (e == 0) { return; }
    e -= d;
    if (e <= 0) {
        // enemy destroyed
        e = 0;
        msgcolor = labelcolor;
        msg = "Destroyed!";
        addlog ("Enemy destroyed");
System.println("enemy destroyed");
        destroyXY = xy;
System.println("damageenemy() actionXY = "+actionXY+" / ship = "+ship);
        sect[destroyXY[0]][destroyXY[1]] = null;
        quad[ship[0]][ship[1]][0]--;
        enemies--;
        destroying = true;
        deseg = 0;
    } else {
        msgcolor = labelcolor;
        tmp = e*100/enemyenergy;
        if (tmp == 0) { tmp = 1; }
        msg = "Enemy "+tmp+"%";
        addlog (msg);
System.println("enemy damaged");
    }
    esect[xy[0]][xy[1]] = e;
}

function repairship() {
    var h = 0;
    for (var i=0;i<health.size();i++) {
        if (health[i] < maxhealth) {
            h += maxhealth-health[i];
            health[i] = maxhealth;
        }
    }
    h = h / maxhealth;
    if (h < 1) { h = 1; }
    days -= h;
    msgcolor = labelcolor;
    if (h == 1) {
        msg = "Repair 1 day";
    } else {
        msg = "Repair "+h+" days";
    }
    addlog(msg);
}

// returns the ship's location in the sector as [x,y]
function findship() {
    for (var i=0;i<grid;i++) {
        for (var j=0;j<grid;j++) {
            if (sect[i][j] == 3) {
                return [i,j];
            }
        }
    }
    return [0,0];
}

function dist(xy1,xy2) {
    var l1 = (xy1[0]-xy2[0]).abs();
    var l2 = (xy1[1]-xy2[1]).abs();
    return Math.sqrt(l1*l1+l2*l2);
}

// Converts grid coordinates to actual pixel [x,y] coordinates
function gridXY(xy) {
    return [bigXY[0]+xy[0]*big1WH[0],bigXY[1]+xy[1]*big1WH[1]];
}

// Converts pixel [x,y] coordinates to grid coordinates and distance from center (0-100) as [x,y,d]
function XYgrid(xy) {
    // calc how far into the grid the point is
    var x = ((1.0*xy[0]-bigXY[0])/big1WH[0]+0.5).toNumber();
    var y = ((1.0*xy[1]-bigXY[1])/big1WH[1]+0.5).toNumber();
    var d = dist(xy,gridXY([x,y]))*100/(big1WH[0]/2);
    return [x,y,d];
}

// Determine if the x,y coodinates are by a base
function bybase(xy) {
    var x = xy[0];
    var y = xy[1];
    if (x>0) {
        if (sect[x-1][y] == 1) { return true; }
    }
    if (x<grid-1) {
        if (sect[x+1][y] == 1) { return true; }
    }
    if (y>0) {
        if (sect[x][y-1] == 1) { return true; }
    }
    if (y<grid-1) {
        if (sect[x][y+1] == 1) { return true; }
    }
    return false;
}

function enemyturn() {
    var xy = findship();
    var d, l, h;
    for (var i=0;i<grid;i++) {
        for (var j=0;j<grid;j++) {
            if (sect[i][j] == 0) {
                tmp = gridXY([i,j]);
                tmp2 = gridXY(xy);
                l = dist([i,j],xy);
                l = l * 2;  // More segments = better hit detection
                var x = (tmp2[0]-tmp[0])/l;
                var y = (tmp2[1]-tmp[1])/l;
                tmp4 = tmp2;
                for (var k=0;k<grid*3;k++) {
                    tmp2 = [tmp[0]+k*x,tmp[1]+k*y];
                    tmp3 = XYgrid(tmp2);
                    tmp5 = -1;
                    if (tmp3[0] >= 0 and tmp3[0] < grid and tmp3[1] >= 0 and tmp3[1] < grid) {
                        // still within the grid
                        tmp4 = tmp2;
                        if (tmp3[2] <= 85) {
                            // close enough to the center of a sector grid
                            tmp5 = sect[tmp3[0]][tmp3[1]];
                            if (tmp5 == 0) { tmp5 = null; }  // no friendly fire
                        } else {
                            tmp5 = null;
                        }
                    }
                    if (tmp5 != null) {
                        break;
                    }
                }
                tmp = [tmp[0]+big1WH[0]/2,tmp[1]+big1WH[1]/2];
                tmp2 = [tmp4[0]+big1WH[0]/2,tmp4[1]+big1WH[1]/2];
                drawphaser(tmp,tmp2,true,true);
                if (tmp5 == 3) {
                    // damage = 200 to 250 (random)
                    // distance reduces damage by up to 40
                    // health reduces damage by up to 40
                    // phasers always do damage
                    d = 200 + Math.rand() % 50;
                    l = dist(findship(),actionXY)*40/grid;
                    h = 40-health[0]*40/maxhealth;
System.println("Phasers d="+d+", l="+l+", h="+h+", final="+(d-l-h));
                    d = (d - l - h).toNumber();
                    damageship(d);
                }
                wait = 500;
            }
        }
    }
}

function damageship(d) {
    if (shields > d) {
        shields -= d;
        energy -= d;
        d = d / 8;
        tmp = shields*100/energy;
        msgcolor = labelcolor;
        msg = "Shields "+tmp+"%";
    } else {
        d -= shields;
        energy -= shields;
        d = d + shields/8;
        shields = 0;
        msgcolor = labelcolor;
        msg = "Shields down!";
    }
    addlog(msg);
    var tried = [false,false,false];
    dtaken += d;
    while (d > 0) {
        tmp = Math.rand() % 3;
        if (d > health[tmp]) {
            d -= health[tmp];
            health[tmp] = 0;
        } else {
            health[tmp] -= d;
            d = 0;
        }
        tried[tmp] = true;
        if (tried[0] and tried[1] and tried[2]) {
            d=0;
        }
    }
}

function buildstarfield(tdc) {
    tmp = 200;
    tmp2 = tdc.getWidth();
    tmp3 = tdc.getHeight();
    while (tmp > 0) {
        tdc.setColor(starfieldcolors[Math.rand() % starfieldcolors.size()],-1);
        if (Math.rand() % 8 == 0) {
            tdc.fillCircle(Math.rand() % tmp2, Math.rand() % tmp3, 1);
        } else {
            tdc.drawPoint(Math.rand() % tmp2, Math.rand() % tmp3);
        }
        tmp--;
    }
}

function penwidth(w) {
    if (w < 1) { w = 1; }
    mydc.setPenWidth(w);
}

function addlog(m) {
    var s = shiplog.size();
    var t = Time.now().value();
    if (settingshields == 2) {
        shiplog[s-1] = [t,m];
        return;
    }
    shiplog.add([t,m]);
}

function newgame() {
    state = 0;
    shiplog = [];
    savegame();
}

function newgame2() {
System.println("newgame2 called");
    // Set game details
    state = 1;
    maxenemies = grid*4/3 + difficulty*grid/2;
    maxdays = grid*6 - difficulty*grid/2;
    bases = grid-1 - difficulty*grid/4;
    maxenergy = grid*500 - difficulty*grid*50;
    docks = 0;
    dtaken = 0;
    ddealt = 0;
    addlog("Mission started");

    // Init quad
    quad = [];
    scanned = [];
    for (var i=0;i<grid;i++) {
        tmp = [];
        tmp2 = [];
        for (var j=0;j<grid;j++) {
            tmp.add([0,0,0]);
            tmp2.add(false);
        }
        quad.add(tmp);
        scanned.add(tmp2);
    }
    // Place enemies
    enemies = 0;
    while (enemies < maxenemies) {
        tmp = Math.rand() % grid;
        tmp2 = Math.rand() % grid;
        if (quad[tmp][tmp2][0] < 3) {
            quad[tmp][tmp2][0]++;
            enemies++;
        }
    }
    // Place bases
    tmp3 = 0;
    while (tmp3 < bases) {
        tmp = Math.rand() % grid;
        tmp2 = Math.rand() % grid;
        if (quad[tmp][tmp2][1] == 0) {
            quad[tmp][tmp2][1]++;
            tmp3++;
        }
    }
    // Place stars
    tmp3 = 0;
    while (tmp3 < grid*grid*grid/2) {
        tmp = Math.rand() % grid;
        tmp2 = Math.rand() % grid;
        if (quad[tmp][tmp2][2] < grid-1) {
            quad[tmp][tmp2][2]++;
            tmp3++;
        }
    }
    // Place our ship
    ship = [Math.rand() % grid, Math.rand() % grid];
    LRS();
    // Randomize current sector
    energy = maxenergy;
    shields = 0;
    health = [maxhealth,maxhealth,maxhealth];
    torps = 10;
    days = maxdays;
    disp = "S";
    traveling = false;
    destroying = false;
    firing = false;
    justwarped = false;
    action = null;
    lastmsg = new Time.Moment(0);
    randsect();
    savegame();
}

function savegame() {
    if (state == 1 or state == 2) {
        if (enemies == 0 or days <= 0) {
            if (days < 0) { days = 0; }
            state = 3;
            if (enemies == 0) {
                addlog("Success!");
            } else if (days > 0) {
                addlog("Resigned");
            } else {
                addlog("Defeat!");
            }
System.println("Game over: enemies="+enemies+" days="+days+" energy="+energy);
        }
    }
    game = {
        "ver" => 1,
        "state" => state,
        "grid" => grid,
        "difficulty" => difficulty,
        "quad" => quad,
        "scanned" => scanned,
        "sect" => sect,
        "esect" => esect,
        "ship" => ship,
        "energy" => energy,
        "shields" => shields,
        "autoshields" => autoshields,
        "health" => health,
        "torps" => torps,
        "days" => days,
        "enemies" => enemies,
        "disp" => disp,
        "maxenemies" => maxenemies,
        "maxdays" => maxdays,
        "bases" => bases,
        "maxenergy" => maxenergy,
        "docks" => docks,
        "dtaken" => dtaken,
        "ddealt" => ddealt,
        "shiplog" => shiplog
    };
    Storage.setValue("game",game);
}

function loadgame() {
    game = Storage.getValue("game");
    if (game == null) { 
        newgame();
    }
    state = game.get("state");
    grid = game.get("grid");
    difficulty = game.get("difficulty");
    quad = game.get("quad");
    scanned = game.get("scanned");
    sect = game.get("sect");
    esect = game.get("esect");
    ship = game.get("ship");
    energy = game.get("energy");
    shields = game.get("shields");
    autoshields = game.get("autoshields");
    health = game.get("health");
    torps = game.get("torps");
    days = game.get("days");
    enemies = game.get("enemies");
    disp = game.get("disp");
    maxenemies = game.get("maxenemies");
    maxdays = game.get("maxdays");
    bases = game.get("bases");
    maxenergy = game.get("maxenergy");
    docks = game.get("docks");
    dtaken = game.get("dtaken");
    ddealt = game.get("ddealt");
    shiplog = game.get("shiplog");
    if (shiplog == null) { shiplog = []; }
}
