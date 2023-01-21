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

public Action OnClientSayCommand ( int client, const char[] command ) {
    if ( StrEqual ( command[0], "bet", false ) ||
         StrEqual ( command[0], "!bet", false ) ) {

        if ( ! playerIsReal ( client ) ) {
            return Plugin_Continue;
        } else if ( IsPlayerAlive ( client ) ) {
            PrintToChat ( client, "[OSTeamBets]: You can't bet while you're alive." );
            return Plugin_Continue;
        } else if ( bets[client][0] != 0 ) {
            PrintToChat ( client, "[OSTeamBets]: You can't bet more than once per round." );
            return Plugin_Continue;
        } else if ( ! StrEqual ( command[1], "T", false ) &&
                    ! StrEqual ( command[1], "CT", false ) ) {
            PrintToChat ( client, "[OSTeamBets]: Invalid team. Please use 'T' or 'CT'." );
            return Plugin_Continue;
        }


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
/*public void Command_Say ( int client, int args ) {
    char text[256];
    GetCmdArgString ( text, sizeof ( text ) );

    char parts[16][32];
    int partCount = ExplodeString ( text, " ", parts, 16, 32 );

    if ( partCount != 3 ) {
        return;
    }
    if ( StrEqual ( parts[0], "bet", false ) ||
         StrEqual ( parts[0], "!bet", false ) ) {

        if ( ! playerIsReal ( client ) ) {
            return ;
        } else if ( IsPlayerAlive ( client ) ) {
            PrintToChat ( client, "[OSTeamBets]: You can't bet while you're alive." );
            return Plugin_Continue;
        } else if ( bets[client][0] != 0 ) {
            PrintToChat ( client, "[OSTeamBets]: You can't bet more than once per round." );
            return Plugin_Continue;
        } else if ( ! StrEqual ( parts[1], "T", false ) &&
                    ! StrEqual ( parts[1], "CT", false ) ) {
            PrintToChat ( client, "[OSTeamBets]: Invalid team. Please use 'T' or 'CT'." );
            return Plugin_Continue;
        } 
        doBet ( client, parts[1], parts[2] );
    }
    return Plugin_Continue;
}*/

/* COMMANDS */

/* handle bet from user */
/*public void doBet ( int player, const char[] command ) {
    if ( ! playerIsReal ( player ) ) {
        return;
    }
    char betTeam[32] = command[1];
    char betAmount[32] = command[2];

    setTeamSizes ( );
    int playerMoney = getPlayerMoney ( player );

    if ( StrEqual ( betTeam, "T", false ) ) {
        bets[player][0] = 2;
        bets[player][2] = bets[player][1] * ( aliveCT / aliveT );
    } else if ( StrEqual ( betTeam, "CT", false ) ) {
        bets[player][0] = 3;
        bets[player][2] = bets[player][1] * ( aliveT / aliveCT );
    } else {
        PrintToChat ( player, "[OSTeamBets]: Invalid team. Please use 'T' or 'CT'." );
        return;
    }


    if ( isNumeric ( betAmount ) ) {
        int betAmountInt = StringToInt ( betAmount );
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
    PrintToChat ( player, "[OSTeamBets]: You have bet $%d on the %s team with the chance of winning: $%d.", bets[player][1], betTeam, bets[player][2] );
}

public Action Command_Bet_old ( int player, int args ) {
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
        int betAmount = StringToInt ( inAmount );
        if ( betAmount > playerMoney ) {
            PrintToChat ( player, "[OSTeamBets]: You don't have enough money to bet that much." );
            return Plugin_Handled;
        }
        bets[player][1] = betAmount;
        incPlayerMoney ( player, betAmount );

    } else {
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
*/

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
