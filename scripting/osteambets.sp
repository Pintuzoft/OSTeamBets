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

public OnPluginStart() {
    HookEvent ( "round_start", Event_RoundStart );
    HookEvent ( "round_end", Event_RoundEnd );
    RegConsoleCmd("bet", Command_Bet);
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
        if ( ! playerIsReal ( player ) ||
             bets[player][0] == 0 ) {
        
        } else if ( bets[player][0] == winner ) {
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
/* COMMANDS */
public Action Command_Bet ( int player, int args ) {
    char team[8];
    char inAmount[24];
    int playerMoney;

    if ( ! playerIsReal ( player ) ) {
        return Plugin_Handled;
    }
    
    if ( args < 3 ) {
        PrintToChat ( player, "[OSTeamBets]: Invalid arguments. Please use 'bet <team> <amount>'." );
        return Plugin_Handled;
    }

    if ( IsPlayerAlive ( player ) ) {
        PrintToChat ( player, "[OSTeamBets]: You can't bet while you're alive." );
        return Plugin_Handled;
    }

    setTeamSizes ( );
    playerMoney = getPlayerMoney ( player );

    GetCmdArg ( 1, team, sizeof ( team ) );
    GetCmdArg ( 2, inAmount, sizeof ( inAmount ) );

    if ( isNumeric ( inAmount ) ) {
        /* Bet amount is a number */
        int betAmount = StringToInt ( inAmount );
        if ( betAmount > playerMoney ) {
            PrintToChat ( player, "[OSTeamBets]: You don't have enough money to bet that much." );
            return Plugin_Handled;
        }
        bets[player][1] = betAmount;
        incPlayerMoney ( player, betAmount );

    } else {
        /* Bet amount is a string */
        if ( StrEqual ( inAmount, "ALL", false ) ) {
            bets[player][1] = playerMoney;
            incPlayerMoney ( player, playerMoney );

        } else if ( StrEqual ( inAmount, "HALF", false ) ) {
            bets[player][1] = playerMoney / 2;
            incPlayerMoney ( player, bets[player][1] );

        } else if ( StrEqual ( inAmount, "QUARTER", false ) ) {
            bets[player][1] = playerMoney / 4;
            incPlayerMoney ( player, bets[player][1] );

        } else {
            PrintToChat ( player, "[OSTeamBets]: Invalid amount. Please use a number or 'ALL'." );
            return Plugin_Handled;
        }

    } 

    if ( StrEqual ( team, "T", false ) ) {
        bets[player][2] = bets[player][1] * ( aliveCT / aliveT );
        bets[player][0] = 2;

    } else if ( StrEqual ( team, "CT", false ) ) {
        bets[player][2] = bets[player][1] * ( aliveT / aliveCT );
        bets[player][0] = 3;        
        
    } else {
        PrintToChat ( player, "[OSTeamBets]: Invalid team. Please use 'T' or 'CT'." );
        return Plugin_Handled;
    }
    PrintToChat ( player, "[OSTeamBets]: You have bet on %s and can win $%d on your $%d bet.", team, bets[player][2], bets[player][1] );
    
    return Plugin_Handled;
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

public bool isNumeric ( char str[24] ) {
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
