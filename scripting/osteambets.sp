#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
    bets[player][0] = Team
    bets[player][1] = Amount
    bets[player][2] = winnings
*/
int bets[MAXPLAYERS+1][3];
int aliveT = 0;
int aliveCT = 0;

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
   
    if ( ! playerIsReal ( client ) ) {
        return Plugin_Continue;

    } else if ( ! StrEqual ( cmd[0], "bet", false ) && ! StrEqual ( cmd[0], "!bet", false ) ) {
        return Plugin_Continue;

    } else if ( partCount < 3 ) {
        PrintToChat ( client, "[OSTeamBets]: Invalid command. Please use 'bet <T|CT> <amount>'." );
        return Plugin_Continue;
    
    } else if ( IsPlayerAlive ( client ) ) {
        PrintToChat ( client, "[OSTeamBets]: You can't bet while you're alive." );
        return Plugin_Continue;
    
    } else if ( ! StrEqual ( cmd[1], "T", false ) && ! StrEqual ( cmd[1], "CT", false ) ) {
        PrintToChat ( client, "[OSTeamBets]: Invalid team. Please use 'T' or 'CT'." );
        return Plugin_Continue;

    } else if ( bets[client][0] != 0 ) {
        PrintToChat ( client, "[OSTeamBets]: You can't bet more than once per round." );
        return Plugin_Continue;
    } 
    doBet ( client, cmd[1], cmd[2] );
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
                int winnings = bets[player][1] + bets[player][2];
                PrintToChat ( player, "[OSTeamBets]: You have won $%d on your $%d bet!", bets[player][2], bets[player][1] );
                PrintToChat ( player, " \x06+$%d\x01: Your winnings.", winnings );
                incPlayerMoney ( player, winnings );
            
            } else {
                /* LOST */
                PrintToChat ( player, "[OSTeamBets]: You have lost your $%d bet!", bets[player][1] );
            }
            bets[player][0] = 0;
            bets[player][1] = 0;
            bets[player][2] = 0;
        }
    }
}


/* METHODS */

/* handle bet from user */
public void doBet ( int player, char[] betTeam, char[] betAmount ) {
    if ( ! playerIsReal ( player ) ) {
        return;
    }
     
    setTeamSizes ( );
    int playerMoney = getPlayerMoney ( player );
    if ( playerMoney == 0 ) {
        PrintToChat ( player, "[OSTeamBets]: You don't have any money to bet." );
        return;
    }
    if ( isNumeric ( betAmount ) ) {
        int betAmountInt = StringToInt ( betAmount );
        if ( betAmountInt > playerMoney ) {
            PrintToChat ( player, "[OSTeamBets]: Amount is more than you have, so betting all." );
            betAmountInt = playerMoney;
        }
        bets[player][1] = betAmountInt;

    } else {
        if ( StrEqual ( betAmount, "ALL", false ) ) {
            bets[player][1] = playerMoney;
        } else if ( StrEqual ( betAmount, "HALF", false ) ) {
            bets[player][1] = playerMoney / 2;
        } else if ( StrEqual ( betAmount, "QUARTER", false ) ) {
            bets[player][1] = playerMoney / 4;
        } else {
            PrintToChat ( player, "[OSTeamBets]: Invalid amount. Please use a number, 'ALL', 'HALF', or 'QUARTER'." );
            bets[player][0] = 0;
            bets[player][1] = 0;
            bets[player][2] = 0;
            return;
        }
    }
    if ( StrEqual ( betTeam, "T", false ) ) {
        bets[player][0] = 2;
        bets[player][2] = RoundToNearest ( float(bets[player][1]) * ( float(aliveCT) / float(aliveT) ) );
    } else if ( StrEqual ( betTeam, "CT", false ) ) {
        bets[player][0] = 3;
        bets[player][2] = RoundToNearest( float(bets[player][1]) * ( float(aliveT) / float(aliveCT) ) );
    } 
    PrintToChat ( player, "[OSTeamBets]: You have bet $%d on the %s team with the chance of winning: $%d.", bets[player][1], betTeam, bets[player][2] );
    PrintToChat ( player, " \x07-$%d\x01: Your bet is in.", bets[player][1] );
    decPlayerMoney ( player, bets[player][1] );
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
        if ( playerIsAlive ( player ) ) {
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

public bool playerIsAlive ( int player ) {
    if ( IsClientInGame ( player ) ) {
        if ( IsPlayerAlive ( player ) ) {
            return true;
        }
    }
    return false;
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
