#include <sourcemod>
#include <sdktools>
#include <cstrike>

int bets[MAXPLAYERS+1][3];
int aliveT = 0;
int aliveCT = 0;

/*
    [player][0] = Team
    [player][1] = Amount
    [player][2] = winnings
*/

public Plugin:myinfo = {
    name = "OSTeamBets",
    author = "Pintuz",
    description = "A simple plugin for betting on the winning team",
    version = "0.01",
    url = "https://github.com/Pintuzoft/OSTeamBets"
};

public OnPluginStart ( ) {
    HookEvent ( "round_start", Event_RoundStart );
    HookEvent ( "round_end", Event_RoundEnd );
}

public Action OnClientSayCommand ( int client, const char[] command, const char[] sArgs ) {
    char cmd[16][32];
    int partCount = ExplodeString ( sArgs, " ", cmd, 16, 32 );
     
    if ( partCount < 3 ) {
        PrintToChat ( client, "[OSTeamBets]: Invalid command. Please use 'bet <T|CT> <amount>'." );
        return Plugin_Continue;
    }

    if ( StrEqual ( cmd[0], "bet", false ) ||
         StrEqual ( cmd[0], "!bet", false ) ) {

        if ( ! playerIsReal ( client ) ) {
            return Plugin_Continue;
//        } else if ( IsPlayerAlive ( client ) ) {
//            PrintToChat ( client, "[OSTeamBets]: You can't bet while you're alive." );
//            return Plugin_Continue;
        } else if ( bets[client][0] != 0 ) {
            PrintToChat ( client, "[OSTeamBets]: You can't bet more than once per round." );
            return Plugin_Continue;
        } else if ( ! StrEqual ( cmd[1], "T", false ) &&
                    ! StrEqual ( cmd[1], "CT", false ) ) {
            PrintToChat ( client, "[OSTeamBets]: Invalid team. Please use 'T' or 'CT'." );
            return Plugin_Continue;
        } 
        PrintToConsoleAll ( "cmd[1]: %s", cmd[1] );
        PrintToConsoleAll ( "cmd[2]: %s", cmd[2] );
        doBet ( client, cmd[1], cmd[2] );
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

/* EVENTS */
public void Event_RoundStart ( Event event, const char[] name, bool dontBroadcast ) {
    aliveT = 0;
    aliveCT = 0;
    for ( int player = 1; player <= MaxClients; player++ ) {
        if ( bets[player][0] != 0) {
            bets[player][0] = 0;
            bets[player][1] = 0;
            bets[player][2] = 0;
        }
    }
}
public void Event_RoundEnd ( Event event, const char[] name, bool dontBroadcast ) {
    int winner = event.GetInt ( "winner" );

    for ( int player = 1; player <= MaxClients; player++ ) {
        if ( playerIsReal ( player ) && bets[player][0] != 0 ) {
            if ( bets[player][0] == winner ) {
                /* WON */
                PrintToChat ( player, "[OSTeamBets]: You have won $%d on your $%d bet!", bets[player][2], bets[player][1] );
                incPlayerMoney ( player, bets[player][2] );
            
            } else {
                /* LOST */
                PrintToChat ( player, "[OSTeamBets]: You have lost your $%d bet!", bets[player][1] );
                decPlayerMoney ( player, bets[player][1] );
            }
            bets[player][0] = 0;
            bets[player][1] = 0;
            bets[player][2] = 0;
        }
    }
}


/* COMMANDS */

/* handle bet from user */
public void doBet ( int player, char[] betTeam, char[] betAmount ) {
    if ( ! playerIsReal ( player ) ) {
        return;
    }
     
    setTeamSizes ( );
    int playerMoney = getPlayerMoney ( player );
    if ( isNumeric ( betAmount ) ) {
        int betAmountInt = StringToInt ( betAmount );
        PrintToConsoleAll ( "betAmountInt: %d", betAmountInt );

        if ( betAmountInt > playerMoney ) {
            PrintToChat ( player, "[OSTeamBets]: Amount is more than you have, so betting all." );
            betAmountInt = playerMoney;
        }
        bets[player][1] = betAmountInt;
        decPlayerMoney ( player, betAmountInt );

    } else {
        if ( StrEqual ( betAmount, "ALL", false ) ) {
            bets[player][1] = playerMoney;
            decPlayerMoney ( player, playerMoney );

        } else if ( StrEqual ( betAmount, "HALF", false ) ) {
            bets[player][1] = playerMoney / 2;
            decPlayerMoney ( player, bets[player][1] );

        } else if ( StrEqual ( betAmount, "QUARTER", false ) ) {
            bets[player][1] = playerMoney / 4;
            decPlayerMoney ( player, bets[player][1] );

        } else {
            PrintToChat ( player, "[OSTeamBets]: Invalid amount. Please use a number, 'ALL', 'HALF', or 'QUARTER'." );
            return;
        }
    }
    int winnings = 0;
    if ( StrEqual ( betTeam, "T", false ) ) {
        bets[player][0] = 2;
        winnings = RoundToNearest ( float(bets[player][1]) * ( float(aliveCT) / float(aliveT) ) );
    } else if ( StrEqual ( betTeam, "CT", false ) ) {
        bets[player][0] = 3;
        winnings = RoundToNearest( float(bets[player][1]) * ( float(aliveT) / float(aliveCT) ) );
    } 
    PrintToConsoleAll ( "winnings: %d", winnings );
    bets[player][2] = winnings;
    PrintToConsoleAll ( "bets[player][0]: %d", bets[player][0] );
    PrintToConsoleAll ( "bets[player][1]: %d", bets[player][1] );
    PrintToConsoleAll ( "bets[player][2]: %d", bets[player][2] );
    PrintToChat ( player, "[OSTeamBets]: You have bet $%d on the %s team with the chance of winning: $%d.", bets[player][1], betTeam, bets[player][2] );
}

public int getPlayerMoney ( int player ) {

    return GetEntProp ( player, Prop_Send, "m_iAccount" );
}

public void decPlayerMoney ( int player, int amount ) {
    int newAmount = getPlayerMoney ( player ) - amount;
    if ( newAmount < 0 ) {
        newAmount = 0;
    }
    SetEntProp ( player, Prop_Send, "m_iAccount", newAmount );
}

public void incPlayerMoney ( int player, int amount ) {
    int newAmount = getPlayerMoney ( player ) + amount;
    if ( newAmount > 16000 ) {
        newAmount = 16000;
    }
    SetEntProp ( player, Prop_Send, "m_iAccount", newAmount );
}

public void setTeamSizes ( ) {
    aliveT = 0;
    aliveCT = 0;
    for ( int player = 1; player <= MaxClients; player++ ) {
        if ( playerIsReal ( player ) && IsPlayerAlive ( player ) ) {
            if ( GetClientTeam ( player ) == 2 ) {
                aliveT++;
            } else {
                aliveCT++;
            }
        }
    }
}

public bool isNumeric ( char[] str ) {
    int len = strlen ( str );
    for ( int i = 0; i < len; i++ ) {
        if ( str[i] < '0' || str[i] > '9' ) {
            return false;
        }
    }
    return true;
}

public bool playerIsReal ( client ) {
    if ( ! IsClientInGame ( client ) ) {
        return false;
    }
    if ( IsClientInGame ( client ) && 
        ! IsFakeClient ( client ) &&
        ! IsClientSourceTV ( client ) ) {
        return true;
    }
    return false;
}
