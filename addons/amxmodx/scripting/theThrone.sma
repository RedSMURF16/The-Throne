/*
*
*	The Throne by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*   Commands:
*       say /throne [name | all]          "Opens the Throne menu or executes the specified player(s)."
*       say_team /throne [name | all]     "Opens the Throne menu or executes the specified player(s)."
*       say /throne_vote                  "Opens the player voting menu."
*       say_team /throne_vote             "Opens the player voting menu."
*       throne_reload                     "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define THRONE_CHECK                10.0
#define THRONE_OFFSET_BASE          120.0
#define THRONE_OFFSET_MIN           65.0
#define THRONE_OFFSET_MAX           900.0
#define THRONE_OFFSET_STEP          10.0
#define THRONE_GHOST_ALPHA          120
#define THRONE_ROTATION_STEP        22.5
#define ADMIN_ACCESS                ADMIN_RCON
#define ADMIN_ACCESS_VOTE           ADMIN_USER
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define THRONE_KEY                  777270
#define throne_vote_KEY             777271
#define THRONE_ARRAY_ITEM           pev_iuser1
#define THRONE_DEATH_PENALTY        250.0
#define SEQ                         60
#define RELEASE_FORWARD_OFFSET      64.0
#define RELEASE_RIGHT_OFFSET        32.0
#define RELEASE_UP_OFFSET           32.0
#define VIEW_FORWARD_OFFSET         128.0
#define VIEW_RIGHT_OFFSET           64.0
#define VIEW_UP_OFFSET              32.0
#define HUD_Y_STEP                  0.025
#define HUD_Y_MAX                   0.7
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "TheTHRONE_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_THRONE
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_MODEL,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL_ID,
    DTYPE_ARRAY_MODEL_ID
}

enum
{
    FLAG_SHOW               = (1 << 0),
    FLAG_GHOST              = (1 << 1),
    FLAG_GROUND             = (1 << 2),
    FLAG_ACTIVE             = (1 << 3),
    FLAG_USED               = (1 << 4)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    SKIN_1,
    SKIN_2,
    SKIN_3
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_MODEL_THRONE_1[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_THRONE_2[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_THRONE_3[MAX_RESOURCE_PATH_LENGTH],
    Array:SETTING_DEFAULT_SOUND_FLUSH,
    Array:SETTING_DEFAULT_SOUND_DUMP,
    Array:SETTING_DEFAULT_MESSAGE,
    Array:SETTING_DEFAULT_MESSAGE_FORCED,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    SETTING_DEFAULT_HOLD_DURATION[2],
    Float:SETTING_DEFAULT_DUMP_DURATION[2],
    Float:SETTING_DEFAULT_DUMP_INTERVAL[2],
    Float:SETTING_DEFAULT_EXPLOSION_CHANCE,
    Float:SETTING_DEFAULT_SHAKE_DISTANCE,
    SETTING_DEFAULT_SHAKE_AMPLITUDE,
    SETTING_DEFAULT_SHAKE_FREQUENCY,
    SETTING_DEFAULT_SHAKE_DURATION,
    bool:SETTING_WRITE_MESSAGE_ON_THRONE,
    bool:SETTING_THRONE_ALL_EXCLUDE_CALLER,
    bool:SETTING_RELEASE_IF_CAGED,
    bool:SETTING_VOTE_ENABLED,
    Float:SETTING_VOTE_COOLDOWN,
    Float:SETTING_VOTE_DURATION,
    Float:SETTING_VOTE_PERCENTAGE,

    Float:SETTING_HUD_X,
    Float:SETTING_HUD_Y,
    SETTING_HUD_COLOR[3],
    SETTING_HUD_EFFECT,
    Float:SETTING_HUD_FXTIME,
    Float:SETTING_HUD_HOLDTIME,
    Float:SETTING_HUD_FADEIN,
    Float:SETTING_HUD_FADEOUT,

    Float:SETTING_MINS_THRONE_1[3],
    Float:SETTING_MAXS_THRONE_1[3],
    Float:SETTING_MINS_THRONE_2[3],
    Float:SETTING_MAXS_THRONE_2[3],
    Float:SETTING_MINS_THRONE_3[3],
    Float:SETTING_MAXS_THRONE_3[3],

    bool:SETTING_THRONE_LOAD,
    Float:SETTING_THRONE_TASK,
}

enum _:THRONE
{
    THRONE_ID,
    THRONE_ITEM,
    THRONE_FLAGS,
    THRONE_TEAM,
    THRONE_SKIN,
    THRONE_VIEW,
    THRONE_NAME[MAX_VALUE_LENGTH],
    Float:THRONE_DUMP_DURATION[2],
    Float:THRONE_DUMP_INTERVAL[2],
    Float:THRONE_EXPLOSION_CHANCE,

    Float:THRONE_ORIGIN[3],
    Float:THRONE_ANGLES[3],
    Float:THRONE_ORIGIN_THRONE[3],
    Float:THRONE_ORIGIN_RELEASE[3],
    Float:THRONE_ANGLES_RELEASE[3],
    Float:THRONE_MINS[3],
    Float:THRONE_MAXS[3],

    Float:THRONE_NEXT_ACTIVE,
    Float:THRONE_NEXT_OPEN
}

enum _:PLAYER_DATA
{
    PDATA_THRONE_GHOST,
    PDATA_THRONE_MENU,
    bool:PDATA_THRONE_ACTION,
    PDATA_THRONE_ID,
    PDATA_ROTATE_SKIN,
    bool:PDATA_THRONE_HELD,
    PDATA_CURRENT_DUMP[MAX_VALUE_LENGTH],
    PDATA_CURRENT_DUMP_ID,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE,

    Float:PDATA_NEXT_THRONE,
    Float:PDATA_NEXT_CHECK,
    Float:PDATA_NEXT_FREE,
    Float:PDATA_NEXT_DUMP
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT,
    SOUND_FLUSH
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE,
    MENU_VOTE,
    MENU_VOTE_CONFIRM
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_SKIN,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate",
    "menuHandlerVote",
    "menuHandlerVoteConfirm",
}

new g_szCN[] = "thethrone"

new Array:g_aThrone,
    Array:g_aThroneConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    g_iFwdEmitSound, HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink, HamHook:g_iFwdPostThink,
    g_iThrone, g_iThroneConfig, g_iBarTime, Float:g_iHudCurrentY, g_iHudObject_1, g_iHudObject_2, g_iHudObject_3, g_iHudSlot,
    g_szVoteTarget[MAX_VALUE_LENGTH], g_iVoteTargetUserid, g_iVoteNo, g_iVoteYes, Float:g_fVoteNext,
    g_iMaxPlayers, g_iSilentVictim, g_iScreenShake


new Float:g_fThroneOffset[] = { 5.0, 0.0, 17.5 }
new g_szRotateSkin[][] = {"THRONE_ROTATE_SKIN_1", "THRONE_ROTATE_SKIN_2", "THRONE_ROTATE_SKIN_3"}
new g_szModelRPG[MAX_RESOURCE_PATH_LENGTH] = "models/w_rpg.mdl"

public plugin_init()
{
    register_plugin("The Throne", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_TheThrone", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /throne",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Throne menu.")
    register_clcmd("say_team /throne",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Throne menu.")
    register_clcmd("say /throne_vote",        "cmdVote", ADMIN_ACCESS_VOTE, "-- Opens the player voting menu.")
    register_clcmd("say_team /throne_vote",   "cmdVote", ADMIN_ACCESS_VOTE, "-- Opens the player voting menu.")
    register_concmd("throne_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("TheThrone.txt")

    g_iFwdEmitSound = register_forward(FM_EmitSound, "fwdEmitSound")
    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdPostThink = RegisterHam(Ham_Player_PostThink, "player", "fwdPostThink", 1)
    RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iBarTime = get_user_msgid("BarTime")
    g_iScreenShake = get_user_msgid("ScreenShake")
    g_iHudObject_1 = CreateHudSyncObj()
    g_iHudObject_2 = CreateHudSyncObj()
    g_iHudObject_3 = CreateHudSyncObj()
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableThrone()

    throneInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aThrone = ArrayCreate(THRONE)
    g_aThroneConfig = ArrayCreate(THRONE)
    g_eSettings[SETTING_DEFAULT_SOUND_FLUSH] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_DUMP] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    precache_model(g_szModelRPG)
    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aThrone)
    ArrayDestroy(g_aThroneConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_FLUSH])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_DUMP])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])
}

stock throneToggleTarget(id, iTarget)
{
    new eThrone[THRONE], iItem
    if ( g_eSettings[SETTING_RELEASE_IF_CAGED]
    && (iItem = throneGet(eThrone, g_ePlayerData[iTarget][PDATA_THRONE_ID])) != -1 )
    {
        engfunc(EngFunc_SetOrigin, iTarget, eThrone[THRONE_ORIGIN_RELEASE])
        set_pev(iTarget, pev_angles, eThrone[THRONE_ANGLES_RELEASE])
        set_pev(iTarget, pev_v_angle, eThrone[THRONE_ANGLES_RELEASE])
        set_pev(iTarget, pev_fixangle, 1)

        eThrone[THRONE_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aThrone, iItem, eThrone)
        g_ePlayerData[iTarget][PDATA_THRONE_ID] = 0
        return 1
    }

    for ( iItem = 0; iItem < g_iThrone; iItem ++ )
    {
        ArrayGetArray(g_aThrone, iItem, eThrone)
        if ( eThrone[THRONE_FLAGS] & FLAG_USED )
            continue

        throneThrone(eThrone, iTarget, true)
        ArraySetArray(g_aThrone, iItem, eThrone)
        return 1
    }

    client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_NO_THRONE")
    return 0
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    new szTarget[64]
    read_argv(2, szTarget, charsmax(szTarget))
    remove_quotes(szTarget)
    if ( !szTarget[0] )
    {
        throneSound(id, SOUND_MENU_NAV)
        throneMenu(id, MENU_ROOT)
        return PLUGIN_HANDLED
    }

    new iArgIndex = 2
    new bool:bProcessed[33]
    while ( szTarget[0] )
    {
        if ( equali(szTarget, "all") )
        {
            for ( new iTarget = 1; iTarget <= g_iMaxPlayers; iTarget ++ )
            {
                if ( !is_user_connected(iTarget) || bProcessed[iTarget]
                || (g_eSettings[SETTING_THRONE_ALL_EXCLUDE_CALLER] && iTarget == id) )
                    continue

                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                    continue

                if ( !throneToggleTarget(id, iTarget) )
                    break
            }
        }
        else
        {
            new iTarget = cmd_target(id, szTarget, CMDTARGET_ALLOW_SELF)
            if ( iTarget && !bProcessed[iTarget] )
            {
                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                {
                    client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_NOT_ALIVE")
                }
                else if ( !throneToggleTarget(id, iTarget) )
                {
                    break
                }
            }
        }

        iArgIndex ++
        szTarget[0] = EOS
        read_argv(iArgIndex, szTarget, charsmax(szTarget))
        remove_quotes(szTarget)
    }

    return PLUGIN_HANDLED
}

public cmdVote(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    if ( !g_eSettings[SETTING_VOTE_ENABLED] )
    {
        client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_VOTE_DISABLED")
        return PLUGIN_HANDLED
    }

    if ( task_exists(throne_vote_KEY)
    || get_gametime() < g_fVoteNext )
    {
        client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_VOTE_COOLDOWN")
        return PLUGIN_HANDLED
    }

    new iAlive
    for ( new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer ++ )
        if ( is_user_alive(iPlayer) )
            iAlive ++

    if ( !iAlive )
    {
        client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_NO_VOTE_TARGETS")
        return PLUGIN_HANDLED
    }

    throneSound(id, SOUND_MENU_NAV)
    throneMenu(id, MENU_VOTE)
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    throneReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        ArrayClear(g_aThroneConfig)
        g_iThroneConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/TheThrone.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eThrone[THRONE], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iThroneConfig )
                            ArrayPushArray(g_aThroneConfig, eThrone)

                        copy(eThrone[THRONE_NAME], charsmax(eThrone[THRONE_NAME]), szData)
                        eThrone[THRONE_FLAGS]                   = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eThrone[THRONE_TEAM]                    = g_eSettings[SETTING_DEFAULT_TEAM]
                        eThrone[THRONE_DUMP_DURATION][0]        = g_eSettings[SETTING_DEFAULT_DUMP_DURATION][0]
                        eThrone[THRONE_DUMP_DURATION][1]        = g_eSettings[SETTING_DEFAULT_DUMP_DURATION][1]
                        eThrone[THRONE_DUMP_INTERVAL][0]        = g_eSettings[SETTING_DEFAULT_DUMP_INTERVAL][0]
                        eThrone[THRONE_DUMP_INTERVAL][1]        = g_eSettings[SETTING_DEFAULT_DUMP_INTERVAL][1]
                        eThrone[THRONE_EXPLOSION_CHANCE]        = g_eSettings[SETTING_DEFAULT_EXPLOSION_CHANCE]

                        iSection = SECTION_THRONE
                        g_iThroneConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_MODEL_THRONE_1") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_THRONE_1], charsmax(g_eSettings[SETTING_MODEL_THRONE_1]))
                        else if ( equali(szKey, "SETTING_MODEL_THRONE_2") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_THRONE_2], charsmax(g_eSettings[SETTING_MODEL_THRONE_2]))
                        else if ( equali(szKey, "SETTING_MODEL_THRONE_3") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_THRONE_3], charsmax(g_eSettings[SETTING_MODEL_THRONE_3]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_FLUSH") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_FLUSH], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_FLUSH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_DUMP") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_DUMP], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_DUMP]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE_FORCED") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HOLD_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HOLD_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_HOLD_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DUMP_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DUMP_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_DUMP_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DUMP_INTERVAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DUMP_INTERVAL], charsmax(g_eSettings[SETTING_DEFAULT_DUMP_INTERVAL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXPLOSION_CHANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXPLOSION_CHANCE], charsmax(g_eSettings[SETTING_DEFAULT_EXPLOSION_CHANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]))
                        else if ( equali(szKey, "SETTING_WRITE_MESSAGE_ON_THRONE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_WRITE_MESSAGE_ON_THRONE], charsmax(g_eSettings[SETTING_WRITE_MESSAGE_ON_THRONE]))
                        else if ( equali(szKey, "SETTING_THRONE_ALL_EXCLUDE_CALLER") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_THRONE_ALL_EXCLUDE_CALLER], charsmax(g_eSettings[SETTING_THRONE_ALL_EXCLUDE_CALLER]))
                        else if ( equali(szKey, "SETTING_RELEASE_IF_CAGED") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_RELEASE_IF_CAGED], charsmax(g_eSettings[SETTING_RELEASE_IF_CAGED]))
                        else if ( equali(szKey, "SETTING_VOTE_ENABLED") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_VOTE_ENABLED], charsmax(g_eSettings[SETTING_VOTE_ENABLED]))
                        else if ( equali(szKey, "SETTING_VOTE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_VOTE_COOLDOWN], charsmax(g_eSettings[SETTING_VOTE_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_VOTE_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_VOTE_DURATION], charsmax(g_eSettings[SETTING_VOTE_DURATION]))
                        else if ( equali(szKey, "SETTING_VOTE_PERCENTAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_VOTE_PERCENTAGE], charsmax(g_eSettings[SETTING_VOTE_PERCENTAGE]))
                        else if ( equali(szKey, "SETTING_HUD_X") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_X], charsmax(g_eSettings[SETTING_HUD_X]))
                        else if ( equali(szKey, "SETTING_HUD_Y") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_Y], charsmax(g_eSettings[SETTING_HUD_Y]))
                        else if ( equali(szKey, "SETTING_HUD_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_COLOR], charsmax(g_eSettings[SETTING_HUD_COLOR]))
                        else if ( equali(szKey, "SETTING_HUD_EFFECT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_EFFECT], charsmax(g_eSettings[SETTING_HUD_EFFECT]))
                        else if ( equali(szKey, "SETTING_HUD_FXTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FXTIME], charsmax(g_eSettings[SETTING_HUD_FXTIME]))
                        else if ( equali(szKey, "SETTING_HUD_HOLDTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_HOLDTIME], charsmax(g_eSettings[SETTING_HUD_HOLDTIME]))
                        else if ( equali(szKey, "SETTING_HUD_FADEIN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEIN], charsmax(g_eSettings[SETTING_HUD_FADEIN]))
                        else if ( equali(szKey, "SETTING_HUD_FADEOUT") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEOUT], charsmax(g_eSettings[SETTING_HUD_FADEOUT]))
                        else if ( equali(szKey, "SETTING_MINS_THRONE_1") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_THRONE_1], charsmax(g_eSettings[SETTING_MINS_THRONE_1]))
                        else if ( equali(szKey, "SETTING_MAXS_THRONE_1") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_THRONE_1], charsmax(g_eSettings[SETTING_MAXS_THRONE_1]))
                        else if ( equali(szKey, "SETTING_MINS_THRONE_2") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_THRONE_2], charsmax(g_eSettings[SETTING_MINS_THRONE_2]))
                        else if ( equali(szKey, "SETTING_MAXS_THRONE_2") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_THRONE_2], charsmax(g_eSettings[SETTING_MAXS_THRONE_2]))
                        else if ( equali(szKey, "SETTING_MINS_THRONE_3") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_THRONE_3], charsmax(g_eSettings[SETTING_MINS_THRONE_3]))
                        else if ( equali(szKey, "SETTING_MAXS_THRONE_3") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_THRONE_3], charsmax(g_eSettings[SETTING_MAXS_THRONE_3]))
                        else if ( equali(szKey, "SETTING_THRONE_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_THRONE_LOAD], charsmax(g_eSettings[SETTING_THRONE_LOAD]))
                        else if ( equali(szKey, "SETTING_THRONE_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_THRONE_TASK], charsmax(g_eSettings[SETTING_THRONE_TASK]))
                    }
                    case SECTION_THRONE:
                    {
                        if ( equali(szKey, "THRONE_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eThrone[THRONE_TEAM], charsmax(eThrone[THRONE_TEAM]))
                        else if ( equali(szKey, "THRONE_DUMP_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThrone[THRONE_DUMP_DURATION], charsmax(eThrone[THRONE_DUMP_DURATION]))
                        else if ( equali(szKey, "THRONE_DUMP_INTERVAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThrone[THRONE_DUMP_INTERVAL], charsmax(eThrone[THRONE_DUMP_INTERVAL]))
                        else if ( equali(szKey, "THRONE_EXPLOSION_CHANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eThrone[THRONE_EXPLOSION_CHANCE], charsmax(eThrone[THRONE_EXPLOSION_CHANCE]))
                    }
                }
            }
        }
    }

    if ( g_iThroneConfig )
        ArrayPushArray(g_aThroneConfig, eThrone)
    else
        set_fail_state("No The Thrones were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eThrone[THRONE], iItem
    if ( g_ePlayerData[id][PDATA_THRONE_GHOST]
    && (iItem = throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_GHOST])) != -1 )
    {
        throneKill(eThrone[THRONE_ID])
        throneRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_THRONE_GHOST]  = 0
    g_ePlayerData[id][PDATA_THRONE_MENU]   = 0
}

stock throneInit()
{
    g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
    if ( g_eSettings[SETTING_THRONE_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock throneMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "THRONE_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_ROOT_STATUS"); }
        case MENU_ROTATE:           { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_ROOT_ROTATE"); }
        case MENU_VOTE:             { menuVote(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_ROOT_VOTE"); }
        case MENU_VOTE_CONFIRM:     { menuVoteConfirm(id, iMenu);   format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_ROOT_VOTE_CONFIRM", g_szVoteTarget); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "THRONE_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROOT_NOCLIP", id, (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? "THRONE_ON" : "THRONE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROOT_GODMODE", id, (pev(id, pev_takedamage) == DAMAGE_NO) ? "THRONE_ON" : "THRONE_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iThrone >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_LIMIT", MAX_ENT)

                throneSound(id, SOUND_MENU_REMOVE)
                throneMenu(id, MENU_ROOT)
            }
            else
            {
                throneSound(id, SOUND_MENU_NAV)
                throneMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iThrone )
            {
                client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_NO_THRONE")

                throneSound(id, SOUND_MENU_REMOVE)
                throneMenu(id, MENU_ROOT)
            }
            else
            {
                throneSound(id, SOUND_MENU_NAV)
                throneMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iThrone )
            {
                client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_NO_THRONE")

                throneSound(id, SOUND_MENU_REMOVE)
                throneMenu(id, MENU_ROOT)
            }
            else
            {
                throneSound(id, SOUND_MENU_REMOVE)
                throneMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            throneNoClip(id)
        }
        case ROOT_GODMODE:
        {
            throneGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eThrone[THRONE], szItem[64]
    for ( new i = 0; i < g_iThroneConfig; i ++ )
    {
        ArrayGetArray(g_aThroneConfig, i, eThrone)

        copy(szItem, charsmax(szItem), eThrone[THRONE_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        throneSound(id, SOUND_MENU_NAV)
        throneMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    throneCreate(id, item)
    throneSound(id, SOUND_MENU_NAV)
    throneMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eThrone[THRONE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_REMOVE_CURRENT", eThrone[THRONE_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    throneSelect(eThrone, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)
}

public menuHandlerRemove(id, menu, item)
{
    new eThrone[THRONE]
    ArrayGetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        throneSelect(eThrone, eThrone[THRONE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THRONE_MENU] >= g_iThrone - 1 )
                g_ePlayerData[id][PDATA_THRONE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THRONE_MENU] ++

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THRONE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THRONE_MENU] = g_iThrone - 1
            else
                g_ePlayerData[id][PDATA_THRONE_MENU] --

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eThrone[THRONE_FLAGS] &= ~FLAG_ACTIVE
            throneSetState(eThrone)
            throneKill(eThrone[THRONE_ID])
            throneRemove(g_ePlayerData[id][PDATA_THRONE_MENU])

            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_REMOVE_CURRENT", eThrone[THRONE_NAME])
            g_ePlayerData[id][PDATA_THRONE_MENU] = 0

            throneSound(id, g_iThrone > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            throneMenu(id, g_iThrone > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iThrone )
            {
                ArrayGetArray(g_aThrone, 0, eThrone)
                eThrone[THRONE_FLAGS] &= ~FLAG_ACTIVE

                throneSetState(eThrone)
                throneKill(eThrone[THRONE_ID])
                throneRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_THRONE_MENU] = 0

            throneSound(id, SOUND_MENU_ALERT)
            throneMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                throneSound(id, SOUND_MENU_NAV)
                throneMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THRONE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THRONE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eThrone[THRONE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_SHOW_CURRENT",
    eThrone[THRONE_FLAGS] & FLAG_SHOW ? "\y" : "\r", eThrone[THRONE_NAME], id, eThrone[THRONE_FLAGS] & FLAG_SHOW ? "THRONE_SHOWN" : "THRONE_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    throneSelect(eThrone, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)
}

public menuHandlerShow(id, menu, item)
{
    new eThrone[THRONE]
    ArrayGetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        throneSelect(eThrone, eThrone[THRONE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THRONE_MENU] >= g_iThrone - 1 )
                g_ePlayerData[id][PDATA_THRONE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THRONE_MENU] ++

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THRONE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THRONE_MENU] = g_iThrone - 1
            else
                g_ePlayerData[id][PDATA_THRONE_MENU] --

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eThrone[THRONE_FLAGS] ^= FLAG_SHOW
            if ( eThrone[THRONE_FLAGS] & FLAG_SHOW )
                eThrone[THRONE_FLAGS] |= FLAG_ACTIVE
            else
                eThrone[THRONE_FLAGS] &= ~FLAG_ACTIVE
            throneSetState(eThrone)

            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_SHOW_CURRENT",
            eThrone[THRONE_NAME], id, eThrone[THRONE_FLAGS] & FLAG_SHOW ? "THRONE_CHAT_SHOWN" : "THRONE_CHAT_HIDDEN")
            ArraySetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iThrone; i ++ )
            {
                ArrayGetArray(g_aThrone, i, eThrone)
                eThrone[THRONE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                throneSetState(eThrone)

                ArraySetArray(g_aThrone, i, eThrone)
            }

            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_SHOW_ALL_SHOWN")
            throneSound(id, SOUND_MENU_ALERT)
            throneMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iThrone; i ++ )
            {
                ArrayGetArray(g_aThrone, i, eThrone)
                eThrone[THRONE_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                throneSetState(eThrone)

                ArraySetArray(g_aThrone, i, eThrone)
            }

            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_SHOW_ALL_HIDDEN")
            throneSound(id, SOUND_MENU_ALERT)
            throneMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                throneSound(id, SOUND_MENU_NAV)
                throneMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THRONE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THRONE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eThrone[THRONE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_STATUS_CURRENT",
    eThrone[THRONE_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eThrone[THRONE_NAME], id, eThrone[THRONE_FLAGS] & FLAG_ACTIVE ? "THRONE_ENABLED" : "THRONE_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    throneSelect(eThrone, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)
}

public menuHandlerStatus(id, menu, item)
{
    new eThrone[THRONE]
    ArrayGetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        throneSelect(eThrone, eThrone[THRONE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_THRONE_MENU] >= g_iThrone - 1 )
                g_ePlayerData[id][PDATA_THRONE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_THRONE_MENU] ++

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_THRONE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_THRONE_MENU] = g_iThrone - 1
            else
                g_ePlayerData[id][PDATA_THRONE_MENU] --

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eThrone[THRONE_FLAGS] ^= FLAG_ACTIVE
            throneSetState(eThrone)

            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_STATUS_CURRENT",
            eThrone[THRONE_NAME], id, eThrone[THRONE_FLAGS] & FLAG_ACTIVE ? "THRONE_CHAT_ENABLED" : "THRONE_CHAT_DISABLED")
            ArraySetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iThrone; i ++ )
            {
                ArrayGetArray(g_aThrone, i, eThrone)
                eThrone[THRONE_FLAGS] |= FLAG_ACTIVE
                throneSetState(eThrone)

                ArraySetArray(g_aThrone, i, eThrone)
            }

            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_STATUS_ALL_ENABLED")
            throneSound(id, SOUND_MENU_ALERT)
            throneMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iThrone; i ++ )
            {
                ArrayGetArray(g_aThrone, i, eThrone)
                eThrone[THRONE_FLAGS] &= ~FLAG_ACTIVE
                throneSetState(eThrone)

                ArraySetArray(g_aThrone, i, eThrone)
            }

            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_STATUS_ALL_DISABLED")
            throneSound(id, SOUND_MENU_ALERT)
            throneMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                throneSound(id, SOUND_MENU_NAV)
                throneMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_THRONE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_THRONE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eThrone[THRONE]
    if ( throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROTATE_GROUND",
    id, eThrone[THRONE_FLAGS] & FLAG_GROUND ? "THRONE_ON" : "THRONE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROTATE_SKIN", id, g_szRotateSkin[g_ePlayerData[id][PDATA_ROTATE_SKIN]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "THRONE_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eThrone[THRONE], iItem
    if ( (iItem = throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eThrone[THRONE_ID], pev_angles, eThrone[THRONE_ANGLES])
            eThrone[THRONE_ANGLES][1] -= THRONE_ROTATION_STEP
            if ( eThrone[THRONE_ANGLES][1] < -180.0 ) eThrone[THRONE_ANGLES][1] += 360.0

            set_pev(eThrone[THRONE_ID], pev_angles, eThrone[THRONE_ANGLES])
            ArraySetArray(g_aThrone, iItem, eThrone)

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eThrone[THRONE_ID], pev_angles, eThrone[THRONE_ANGLES])
            eThrone[THRONE_ANGLES][1] += THRONE_ROTATION_STEP
            if ( eThrone[THRONE_ANGLES][1] > 180.0 ) eThrone[THRONE_ANGLES][1] -= 360.0

            set_pev(eThrone[THRONE_ID], pev_angles, eThrone[THRONE_ANGLES])
            ArraySetArray(g_aThrone, iItem, eThrone)

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eThrone[THRONE_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aThrone, iItem, eThrone)

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_ROTATE)
        }
        case ROTATE_SKIN:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SKIN] > SKIN_3 )
                g_ePlayerData[id][PDATA_ROTATE_SKIN] = SKIN_1

            eThrone[THRONE_SKIN] = g_ePlayerData[id][PDATA_ROTATE_SKIN]
            switch( eThrone[THRONE_SKIN] )
            {
                case SKIN_1: engfunc(EngFunc_SetModel, eThrone[THRONE_ID], g_eSettings[SETTING_MODEL_THRONE_1])
                case SKIN_2: engfunc(EngFunc_SetModel, eThrone[THRONE_ID], g_eSettings[SETTING_MODEL_THRONE_2])
                case SKIN_3: engfunc(EngFunc_SetModel, eThrone[THRONE_ID], g_eSettings[SETTING_MODEL_THRONE_3])
            }

            ArraySetArray(g_aThrone, iItem, eThrone)
            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            throneTrace(eThrone, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THRONE_GHOST] = 0

            eThrone[THRONE_FLAGS] &= ~FLAG_GHOST
            eThrone[THRONE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eThrone[THRONE_ANGLES][0] = -eThrone[THRONE_ANGLES][0]
            throneSetSize(eThrone)
            throneSetState(eThrone)
            client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_CREATE_NEW", eThrone[THRONE_NAME])

            ArraySetArray(g_aThrone, iItem, eThrone)
            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            throneKill(eThrone[THRONE_ID])
            throneRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THRONE_GHOST] = 0

            throneSound(id, SOUND_MENU_NAV)
            throneMenu(id, MENU_CREATE)
        }
        default:
        {
            throneKill(eThrone[THRONE_ID])
            throneRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_THRONE_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuVote(id, iMenu)
{
    new szName[MAX_NAME_LENGTH], szInfo[8]
    for ( new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer ++ )
    {
        if ( !is_user_alive(iPlayer) )
            continue

        get_user_name(iPlayer, szName, charsmax(szName))
        num_to_str(get_user_userid(iPlayer), szInfo, charsmax(szInfo))
        menu_additem(iMenu, szName, szInfo)
    }

    return PLUGIN_HANDLED
}

public menuHandlerVote(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    new szInfo[8]
    menu_item_getinfo(menu, item, _, szInfo, charsmax(szInfo))

    new iUserid = str_to_num(szInfo)
    new iPlayer = find_player("k", iUserid)
    if ( !iPlayer || !is_user_alive(iPlayer) )
    {
        client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_NO_VOTE_TARGETS")
        return PLUGIN_HANDLED
    }

    g_iVoteNo = 0
    g_iVoteYes = 0
    g_iVoteTargetUserid = iUserid
    get_user_name(iPlayer, g_szVoteTarget, charsmax(g_szVoteTarget))
    set_task(g_eSettings[SETTING_VOTE_DURATION], "taskVoteEnd", throne_vote_KEY)
    for ( new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer ++ )
    {
        if ( !is_user_connected(iPlayer) )
            continue

        throneSound(iPlayer, SOUND_MENU_NAV)
        throneMenu(iPlayer, MENU_VOTE_CONFIRM)
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuVoteConfirm(id, menu)
{
    new szItem[128]
    formatex(szItem, charsmax(szItem), "%L", id, "throne_vote_YES")
    menu_additem(menu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "throne_vote_NO")
    menu_additem(menu, szItem)
}

public menuHandlerVoteConfirm(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    if ( item == 0 )    g_iVoteYes ++
    else                g_iVoteNo ++

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public taskVoteEnd()
{
    new iTotal = g_iVoteYes + g_iVoteNo
    new Float:fPercentage

    if ( iTotal )
        fPercentage = float(g_iVoteYes) / float(iTotal)

    new iTarget = find_player("k", g_iVoteTargetUserid)
    if ( iTotal && fPercentage >= g_eSettings[SETTING_VOTE_PERCENTAGE]
    && iTarget && is_user_alive(iTarget) )
    {
        new eThrone[THRONE], bool:bFoundThrone
        for ( new iItem = 0; iItem < g_iThrone; iItem ++ )
        {
            ArrayGetArray(g_aThrone, iItem, eThrone)

            if ( eThrone[THRONE_FLAGS] & FLAG_USED )
                continue

            throneThrone(eThrone, iTarget, true)
            ArraySetArray(g_aThrone, iItem, eThrone)
            bFoundThrone = true
            break
        }

        if ( !bFoundThrone )
            client_print_color(0, print_team_default, "%L %L", 0, "THRONE_CHAT_TAG", 0, "THRONE_CHAT_NO_THRONE")
        else
            client_print_color(0, print_team_default, "%L %L", 0, "THRONE_CHAT_TAG", 0, "THRONE_CHAT_VOTE_PASSED", g_szVoteTarget)
    }
    else
    {
        client_print_color(0, print_team_default, "%L %L", 0, "THRONE_CHAT_TAG", 0, "THRONE_CHAT_VOTE_FAILED", g_szVoteTarget)
    }

    g_fVoteNext = get_gametime() + g_eSettings[SETTING_VOTE_COOLDOWN]
}

public throneTask()
{
    new eThrone[THRONE], iItem, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( g_ePlayerData[id][PDATA_NEXT_THRONE] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_THRONE] )
            {
                if ( (iItem = throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_ID])) != -1 )
                {
                    g_ePlayerData[id][PDATA_THRONE_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_THRONE] = 0.0

                    throneThrone(eThrone, id)
                    ArraySetArray(g_aThrone, iItem, eThrone)
                }
            }
            else if ( fCurrentTime - g_ePlayerData[id][PDATA_NEXT_CHECK] > 0.1 )
            {
                throneBar(id, 0)
                g_ePlayerData[id][PDATA_THRONE_ID] = 0
                g_ePlayerData[id][PDATA_NEXT_THRONE] = 0.0
            }
        }
        else if ( g_ePlayerData[id][PDATA_NEXT_FREE] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_FREE] )
            {
                if ( (iItem = throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_ID])) != -1 )
                {
                    engfunc(EngFunc_SetView, id, id)
                    engfunc(EngFunc_SetOrigin, id, eThrone[THRONE_ORIGIN_RELEASE])
                    set_pev(id, pev_angles, eThrone[THRONE_ANGLES_RELEASE])
                    set_pev(id, pev_v_angle, eThrone[THRONE_ANGLES_RELEASE])
                    set_pev(id, pev_movetype, MOVETYPE_WALK)
                    g_ePlayerData[id][PDATA_THRONE_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_FREE] = 0.0
                    g_ePlayerData[id][PDATA_THRONE_HELD] = false
                    eThrone[THRONE_FLAGS] &= ~FLAG_USED
                    throneSound(eThrone[THRONE_ID], SOUND_FLUSH, false)
                    engfunc(EngFunc_EmitSound, id, CHAN_VOICE, g_ePlayerData[id][PDATA_CURRENT_DUMP], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)

                    ArraySetArray(g_aThrone, iItem, eThrone)
                }
            }
            else if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_DUMP] )
            {
                if ( (iItem = throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_ID])) != -1 )
                {
                    if ( random_float(0.0, 1.0) <= eThrone[THRONE_EXPLOSION_CHANCE] )
                    {
                        throneExplode(id, eThrone[THRONE_ID])

                        if ( is_user_alive(id) )
                        {
                            engfunc(EngFunc_SetView, id, id)
                            engfunc(EngFunc_SetOrigin, id, eThrone[THRONE_ORIGIN_RELEASE])
                            set_pev(id, pev_angles, eThrone[THRONE_ANGLES_RELEASE])
                            set_pev(id, pev_v_angle, eThrone[THRONE_ANGLES_RELEASE])
                            set_pev(id, pev_movetype, MOVETYPE_WALK)
                            g_ePlayerData[id][PDATA_THRONE_ID] = 0
                            g_ePlayerData[id][PDATA_NEXT_FREE] = 0.0
                            g_ePlayerData[id][PDATA_THRONE_HELD] = false
                            eThrone[THRONE_FLAGS] &= ~FLAG_USED
                            throneSound(eThrone[THRONE_ID], SOUND_FLUSH, false)
                            engfunc(EngFunc_EmitSound, id, CHAN_VOICE, g_ePlayerData[id][PDATA_CURRENT_DUMP], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
                        }
                    }
                    else
                    {
                        new szSound[64], iDump
                        while ( (iDump = random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_DUMP]))) == g_ePlayerData[id][PDATA_CURRENT_DUMP_ID] ) {}
                        g_ePlayerData[id][PDATA_CURRENT_DUMP_ID] = iDump
                        ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_DUMP], g_ePlayerData[id][PDATA_CURRENT_DUMP_ID], szSound, charsmax(szSound))
                        copy(g_ePlayerData[id][PDATA_CURRENT_DUMP], charsmax(g_ePlayerData[][PDATA_CURRENT_DUMP]), szSound)
                        engfunc(EngFunc_EmitSound, id, CHAN_VOICE, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

                        throneShake(eThrone)
                        g_ePlayerData[id][PDATA_NEXT_DUMP] = fCurrentTime + random_float(eThrone[THRONE_DUMP_INTERVAL][0], eThrone[THRONE_DUMP_INTERVAL][1])
                    }
                }
            }
        }
    }
}

stock throneCreate(id, iItem)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    new eThrone[THRONE]
    ArrayGetArray(g_aThroneConfig, iItem, eThrone)
    eThrone[THRONE_ID] = iEnt
    eThrone[THRONE_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_THRONE_GHOST] = eThrone[THRONE_ID]
        g_ePlayerData[id][PDATA_OFFSET] = THRONE_OFFSET_BASE

        eThrone[THRONE_FLAGS] |= FLAG_GHOST
        eThrone[THRONE_SKIN] = g_ePlayerData[id][PDATA_ROTATE_SKIN]
    }

    throneSelect(eThrone, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, THRONE_KEY)
    set_pev(iEnt, THRONE_ARRAY_ITEM, g_iThrone)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    if ( id )
    {
        switch( eThrone[THRONE_SKIN] )
        {
            case SKIN_1: engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_THRONE_1])
            case SKIN_2: engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_THRONE_2])
            case SKIN_3: engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_THRONE_3])
        }
    }

    ArrayPushArray(g_aThrone, eThrone)
    if ( ++ g_iThrone == 1 )
    {
        set_task(g_eSettings[SETTING_THRONE_TASK], "throneTask", THRONE_KEY, .flags = "b")
        EnableThrone()
    }
}

stock throneCreateRelease(eThrone[THRONE])
{
    new Float:fRight[3], Float:fForward[3], Float:fDirection[3], Float:fFrac
    engfunc(EngFunc_AngleVectors, eThrone[THRONE_ANGLES], fForward, fRight, NULL_VECTOR)

    xs_vec_copy(eThrone[THRONE_ORIGIN], eThrone[THRONE_ORIGIN_RELEASE])
    xs_vec_mul_scalar(fForward, RELEASE_FORWARD_OFFSET, fForward)
    xs_vec_mul_scalar(fRight, RELEASE_RIGHT_OFFSET, fRight)
    xs_vec_add(eThrone[THRONE_ORIGIN_RELEASE], fRight, eThrone[THRONE_ORIGIN_RELEASE])
    xs_vec_add(eThrone[THRONE_ORIGIN_RELEASE], fForward, eThrone[THRONE_ORIGIN_RELEASE])
    eThrone[THRONE_ORIGIN_RELEASE][2] += RELEASE_UP_OFFSET

    engfunc(EngFunc_TraceLine, eThrone[THRONE_ORIGIN], eThrone[THRONE_ORIGIN_RELEASE], IGNORE_MONSTERS, eThrone[THRONE_ID], 0)
    get_tr2(0, TR_flFraction, fFrac)
    if ( fFrac < 1.0 )
        get_tr2(0, TR_vecEndPos, eThrone[THRONE_ORIGIN_RELEASE])

    xs_vec_sub(eThrone[THRONE_ORIGIN], eThrone[THRONE_ORIGIN_RELEASE], fDirection)
    engfunc(EngFunc_VecToAngles, fDirection, eThrone[THRONE_ANGLES_RELEASE])
}

stock throneCreateView(eThrone[THRONE])
{
    new Float:fOrigin[3], Float:fAngles[3], Float:fRight[3], Float:fForward[3], Float:fDirection[3], Float:fFrac
    engfunc(EngFunc_AngleVectors, eThrone[THRONE_ANGLES], fForward, fRight, NULL_VECTOR)

    xs_vec_copy(eThrone[THRONE_ORIGIN], fOrigin)
    xs_vec_mul_scalar(fForward, VIEW_FORWARD_OFFSET, fForward)
    xs_vec_mul_scalar(fRight, VIEW_RIGHT_OFFSET, fRight)
    xs_vec_add(fOrigin, fForward, fOrigin)
    xs_vec_add(fOrigin, fRight, fOrigin)
    fOrigin[2] += VIEW_UP_OFFSET

    engfunc(EngFunc_TraceLine, eThrone[THRONE_ORIGIN], fOrigin, IGNORE_MONSTERS, eThrone[THRONE_ID], 0)
    get_tr2(0, TR_flFraction, fFrac)
    if ( fFrac < 1.0 )
        get_tr2(0, TR_vecEndPos, fOrigin)

    // fOrigin[2] -= VIEW_UP_OFFSET
    xs_vec_sub(eThrone[THRONE_ORIGIN], fOrigin, fDirection)
    engfunc(EngFunc_VecToAngles, fDirection, fAngles)
    new iView = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iView) )
        return

    new szCN[32]
    formatex(szCN, charsmax(szCN), "%s_view", g_szCN)
    set_pev(iView, pev_classname, szCN)
    set_pev(iView, pev_movetype, MOVETYPE_NONE)
    set_pev(iView, pev_solid, SOLID_NOT)
    engfunc(EngFunc_SetModel, iView, g_szModelRPG)
    set_pev(iView, pev_rendermode, kRenderTransTexture)
    set_pev(iView, pev_renderamt, 0.0)
    engfunc(EngFunc_SetOrigin, iView, fOrigin)
    set_pev(iView, pev_angles, fAngles)

    eThrone[THRONE_VIEW] = iView
}

public throneRemove(iItem)
{
    new eThrone[THRONE]
    ArrayDeleteItem(g_aThrone, iItem)

    if ( -- g_iThrone == 0 )
    {
        remove_task(THRONE_KEY)
        DisableThrone()
    }

    for ( new i = iItem; i < g_iThrone; i ++ )
    {
        ArrayGetArray(g_aThrone, i, eThrone)
        set_pev(eThrone[THRONE_ID], THRONE_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eThrone[THRONE],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_TheThrone.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iThrone; i ++ )
    {
        ArrayGetArray(g_aThrone, i, eThrone)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eThrone[THRONE_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eThrone[THRONE_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "skin = %d^n", eThrone[THRONE_SKIN])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eThrone[THRONE_ORIGIN][0], eThrone[THRONE_ORIGIN][1], eThrone[THRONE_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eThrone[THRONE_ANGLES][0], eThrone[THRONE_ANGLES][1], eThrone[THRONE_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "THRONE_CHAT_TAG", id, "THRONE_CHAT_SAVE", szFile)
    fclose(iFile)

    throneSound(id, SOUND_MENU_NAV)
    throneMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iSkin, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_TheThrone.ini", szFile)
    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataThrone(iItem, iFlags, iSkin, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "skin") )
            {
                iSkin = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataThrone(iItem, iFlags, iSkin, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataThrone(iItem, iFlags, iSkin, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eThrone[THRONE]
    throneCreate(0, iItem)
    ArrayGetArray(g_aThrone, iCount, eThrone)

    eThrone[THRONE_FLAGS] = iFlags
    eThrone[THRONE_SKIN] = iSkin
    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eThrone[THRONE_ORIGIN])
    xs_vec_copy(fAngles, eThrone[THRONE_ANGLES])
    switch( eThrone[THRONE_SKIN] )
    {
        case SKIN_1: engfunc(EngFunc_SetModel, eThrone[THRONE_ID], g_eSettings[SETTING_MODEL_THRONE_1])
        case SKIN_2: engfunc(EngFunc_SetModel, eThrone[THRONE_ID], g_eSettings[SETTING_MODEL_THRONE_2])
        case SKIN_3: engfunc(EngFunc_SetModel, eThrone[THRONE_ID], g_eSettings[SETTING_MODEL_THRONE_3])
    }

    throneSetBox(eThrone)
    throneSetSize(eThrone)
    throneSetState(eThrone)
    ArraySetArray(g_aThrone, iCount, eThrone)
}

public throneNoClip(id)
{
    set_pev(id, pev_movetype, pev(id, pev_movetype) == MOVETYPE_NOCLIP ? MOVETYPE_WALK : MOVETYPE_NOCLIP)

    throneSound(id, SOUND_MENU_NAV)
    throneMenu(id, MENU_ROOT)
}

public throneGodMode(id)
{
    new Float:flTakeDamage
    pev(id, pev_takedamage, flTakeDamage)
    set_pev(id, pev_takedamage, flTakeDamage == DAMAGE_NO ? DAMAGE_AIM : DAMAGE_NO)

    throneSound(id, SOUND_MENU_NAV)
    throneMenu(id, MENU_ROOT)
}

public fwdEmitSound(iEnt, iChannel, const szSample[])
{
    if ( g_iSilentVictim && iEnt == g_iSilentVictim )
        return FMRES_SUPERCEDE

    return FMRES_IGNORED
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isThrone(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eThrone[THRONE]
    if ( throneGet(eThrone, iEnt) == -1 )
        return HAM_IGNORED

    new Float:fCurrentTime = get_gametime()
    if ( !(eThrone[THRONE_FLAGS] & FLAG_ACTIVE)
    || (eThrone[THRONE_FLAGS] & FLAG_USED)
    || !(eThrone[THRONE_TEAM] & get_user_team(iActivator))
    || fCurrentTime < eThrone[THRONE_NEXT_ACTIVE] )
        return HAM_IGNORED

    g_ePlayerData[iActivator][PDATA_NEXT_CHECK] = fCurrentTime
    if ( !g_ePlayerData[iActivator][PDATA_NEXT_THRONE] )
    {
        new iDuration
        iDuration = random_num(g_eSettings[SETTING_DEFAULT_HOLD_DURATION][0], g_eSettings[SETTING_DEFAULT_HOLD_DURATION][1])

        throneBar(iActivator, iDuration)
        g_ePlayerData[iActivator][PDATA_THRONE_ID] = iEnt
        g_ePlayerData[iActivator][PDATA_NEXT_THRONE] = fCurrentTime + iDuration
    }
    else if ( !fValue )
    {
        throneBar(iActivator, 0)
        g_ePlayerData[iActivator][PDATA_THRONE_ID] = 0
        g_ePlayerData[iActivator][PDATA_NEXT_THRONE] = 0.0
    }

    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isThrone(iEnt) )
        return GetHamReturnStatus() == HAM_SUPERCEDE ? HAM_SUPERCEDE : HAM_IGNORED

    SetHamReturnInteger(FCAP_CONTINUOUS_USE | FCAP_ONOFF_USE)
    return HAM_SUPERCEDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eThrone[THRONE], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_THRONE_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += THRONE_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], THRONE_OFFSET_MIN, THRONE_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= THRONE_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], THRONE_OFFSET_MIN, THRONE_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            throneTrace(eThrone, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_THRONE_ACTION] )
    {
        throneCheck(id)
    }

    return HAM_IGNORED
}

public fwdPostThink(id)
{
    if ( !is_user_alive(id)
    || !g_ePlayerData[id][PDATA_THRONE_HELD] )
        return FMRES_IGNORED

    set_pev(id, pev_sequence, SEQ)
    set_pev(id, pev_gaitsequence, SEQ)
    set_pev(id, pev_framerate, 1.0)
    return FMRES_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_THRONE_MENU] = 0
    if ( g_ePlayerData[id][PDATA_THRONE_GHOST] )
    {
        new eThrone[THRONE], iItem
        if ( (iItem = throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_GHOST])) != -1 )
        {
            throneKill(eThrone[THRONE_ID])
            throneRemove(iItem)
        }

        g_ePlayerData[id][PDATA_THRONE_GHOST] = 0
    }

    if ( g_ePlayerData[id][PDATA_NEXT_FREE] )
    {
        new eThrone[THRONE], iItem
        if ( (iItem = throneGet(eThrone, g_ePlayerData[id][PDATA_THRONE_ID])) != -1 )
        {
            eThrone[THRONE_FLAGS] &= ~FLAG_USED
            ArraySetArray(g_aThrone, iItem, eThrone)
        }

        g_iSilentVictim = 0
        g_ePlayerData[id][PDATA_THRONE_HELD] = false
        g_ePlayerData[id][PDATA_THRONE_ID] = 0
        g_ePlayerData[id][PDATA_NEXT_FREE] = 0.0
        g_ePlayerData[id][PDATA_NEXT_DUMP] = 0.0
        set_pev(id, pev_deadflag, DEAD_DISCARDBODY)
    }
}

stock throneTrace(eThrone[THRONE], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eThrone[THRONE_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eThrone[THRONE_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eThrone[THRONE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eThrone[THRONE_ORIGIN])

    throneSetBox(eThrone)
    throneSetOffset(eThrone)
    set_pev(eThrone[THRONE_ID], pev_origin, eThrone[THRONE_ORIGIN])
}

stock throneCheck(id)
{
    new eThrone[THRONE], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist
    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = THRONE_CHECK
    for ( new i = 0; i < g_iThrone; i ++ )
    {
        ArrayGetArray(g_aThrone, i, eThrone)
        xs_vec_sub(eThrone[THRONE_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eThrone[THRONE_ID], pev_absmin, fMins)
        pev(eThrone[THRONE_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_THRONE_MENU] != iBest )
    {
        ArrayGetArray(g_aThrone, g_ePlayerData[id][PDATA_THRONE_MENU], eThrone)
        throneSelect(eThrone, eThrone[THRONE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_THRONE_MENU] = iBest
        throneMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock throneShake(eThrone[THRONE])
{
    new Float:fOrigin[3]
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        pev(id, pev_origin, fOrigin)
        if ( xs_vec_distance(fOrigin, eThrone[THRONE_ORIGIN]) > g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE] )
            continue

        message_begin(MSG_ONE_UNRELIABLE, g_iScreenShake, .player = id)
        write_short(g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE] * 4096)
        write_short(g_eSettings[SETTING_DEFAULT_SHAKE_DURATION] * 4096)
        write_short(g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY] * 4096)
        message_end()
    }
}

stock throneExplode(id, iThrone)
{
    new Float:fOrigin[3]
    pev(id, pev_origin, fOrigin)
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
    write_byte(TE_EXPLOSION)
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2])
    write_short(0)
    write_byte(0)
    write_byte(0)
    write_byte(TE_EXPLFLAG_NOADDITIVE | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES)
    message_end()

    g_iSilentVictim = id
    ExecuteHamB(Ham_TakeDamage, id, iThrone, iThrone, THRONE_DEATH_PENALTY, DMG_ALWAYSGIB)
}

stock throneSetBox(eThrone[THRONE])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eThrone[THRONE_ANGLES][0] = -eThrone[THRONE_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eThrone[THRONE_ANGLES], fForward, fRight, fUp)
    switch ( eThrone[THRONE_SKIN] )
    {
        case SKIN_1:  xs_vec_copy(g_eSettings[SETTING_MINS_THRONE_1], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_THRONE_1], fMaxs)
        case SKIN_2:  xs_vec_copy(g_eSettings[SETTING_MINS_THRONE_2], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_THRONE_2], fMaxs)
        case SKIN_3:  xs_vec_copy(g_eSettings[SETTING_MINS_THRONE_3], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_THRONE_3], fMaxs)
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eThrone[THRONE_MINS])
    xs_vec_copy(fMaxs, eThrone[THRONE_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock throneSetOffset(eThrone[THRONE])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eThrone[THRONE_MINS][0]
    fGaps[1] = eThrone[THRONE_MAXS][0]
    fGaps[2] = -eThrone[THRONE_MINS][1]
    fGaps[3] = eThrone[THRONE_MAXS][1]
    fGaps[4] = -eThrone[THRONE_MINS][2]
    fGaps[5] = eThrone[THRONE_MAXS][2]

    if ( eThrone[THRONE_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eThrone[THRONE_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eThrone[THRONE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eThrone[THRONE_ID], 0)
        get_tr2(0, TR_vecEndPos, eThrone[THRONE_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eThrone[THRONE_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eThrone[THRONE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eThrone[THRONE_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eThrone[THRONE_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eThrone[THRONE_ORIGIN], fVec1, eThrone[THRONE_ORIGIN])
        }
    }
}

stock throneSetSize(eThrone[THRONE])
{
    throneSelect(eThrone, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eThrone[THRONE_ID], eThrone[THRONE_ORIGIN])
    set_pev(eThrone[THRONE_ID], pev_angles, eThrone[THRONE_ANGLES])
    set_pev(eThrone[THRONE_ID], pev_solid, eThrone[THRONE_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eThrone[THRONE_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eThrone[THRONE_ID], eThrone[THRONE_MINS], eThrone[THRONE_MAXS])
    engfunc(EngFunc_GetAttachment, eThrone[THRONE_ID], 0, eThrone[THRONE_ORIGIN_THRONE], NULL_VECTOR)
    throneCreateRelease(eThrone)
    throneCreateView(eThrone)
}

stock throneSetState(eThrone[THRONE])
{
    if ( eThrone[THRONE_FLAGS] & FLAG_SHOW )
    {
        set_pev(eThrone[THRONE_ID], pev_solid, SOLID_BBOX)
        throneSelect(eThrone, TARGET_CLEAR)
    }
    else
    {
        set_pev(eThrone[THRONE_ID], pev_solid, SOLID_NOT)
        throneSelect(eThrone, TARGET_HIDE)
    }
}

stock throneOffset(eThrone[THRONE], id)
{
    new Float:fAng[3], Float:fFwd[3], Float:fRight[3], Float:fOrigin[3]
    xs_vec_copy(eThrone[THRONE_ANGLES], fAng)
    fAng[0] = 0.0
    fAng[2] = 0.0
    engfunc(EngFunc_AngleVectors, fAng, fFwd, fRight, NULL_VECTOR)

    xs_vec_copy(eThrone[THRONE_ORIGIN_THRONE], fOrigin)
    xs_vec_add_scaled(fOrigin, fFwd, g_fThroneOffset[0], fOrigin)
    xs_vec_add_scaled(fOrigin, fRight, g_fThroneOffset[1], fOrigin)
    fOrigin[2] += g_fThroneOffset[2]

    engfunc(EngFunc_SetOrigin, id, fOrigin)
    set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
    set_pev(id, pev_angles, fAng)
    set_pev(id, pev_v_angle, fAng)
    set_pev(id, pev_fixangle, 1)
}

stock throneThrone(eThrone[THRONE], id, bool:bForced = false)
{
    throneOffset(eThrone, id)
    eThrone[THRONE_FLAGS] |= FLAG_USED
    g_ePlayerData[id][PDATA_THRONE_ID] = eThrone[THRONE_ID]
    g_ePlayerData[id][PDATA_THRONE_HELD] = true
    g_ePlayerData[id][PDATA_NEXT_FREE] = get_gametime() + random_float(eThrone[THRONE_DUMP_DURATION][0], eThrone[THRONE_DUMP_DURATION][1])
    g_ePlayerData[id][PDATA_NEXT_DUMP] = get_gametime() + random_float(eThrone[THRONE_DUMP_INTERVAL][0], eThrone[THRONE_DUMP_INTERVAL][1])
    set_pev(id, pev_movetype, MOVETYPE_NONE)
    engfunc(EngFunc_SetView, id, eThrone[THRONE_VIEW])

    if ( g_eSettings[SETTING_WRITE_MESSAGE_ON_THRONE] )
        throneMessage(id, bForced)
}

stock throneBar(id, iDuration)
{
    message_begin_f(MSG_ONE_UNRELIABLE, g_iBarTime, .player = id)
    write_short(iDuration)
    message_end()
}

stock throneSelect(eThrone[THRONE], iAction)
{
    if ( iAction == TARGET_SELECT )
    {
        if ( eThrone[THRONE_FLAGS] & FLAG_ACTIVE )  { set_pev(eThrone[THRONE_ID], pev_rendercolor, Float:{0.0, 255.0, 0.0}); }
        else                                                { set_pev(eThrone[THRONE_ID], pev_rendercolor, Float:{255.0, 0.0, 0.0}); }

        set_pev(eThrone[THRONE_ID], pev_renderfx, kRenderFxGlowShell)
        set_pev(eThrone[THRONE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eThrone[THRONE_ID], pev_renderamt, 16.0)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_pev(eThrone[THRONE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eThrone[THRONE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eThrone[THRONE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eThrone[THRONE_ID], pev_renderamt, float(THRONE_GHOST_ALPHA))
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_pev(eThrone[THRONE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eThrone[THRONE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eThrone[THRONE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eThrone[THRONE_ID], pev_renderamt, 0.0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_pev(eThrone[THRONE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eThrone[THRONE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eThrone[THRONE_ID], pev_rendermode, kRenderNormal)
        set_pev(eThrone[THRONE_ID], pev_renderamt, 255.0)
    }
}

stock throneMessage(id, bool:bForced = false)
{
    new szName[MAX_NAME_LENGTH], szMessage[128], iHudObject
    get_user_name(id, szName, charsmax(szName))

    if ( bForced )
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])), szMessage, charsmax(szMessage))
    else
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE])), szMessage, charsmax(szMessage))

    switch ( g_iHudSlot )
    {
        case 0:  iHudObject = g_iHudObject_1
        case 1:  iHudObject = g_iHudObject_2
        default: iHudObject = g_iHudObject_3
    }

    set_hudmessage(g_eSettings[SETTING_HUD_COLOR][0], g_eSettings[SETTING_HUD_COLOR][1], g_eSettings[SETTING_HUD_COLOR][2], g_eSettings[SETTING_HUD_X], g_iHudCurrentY,
    g_eSettings[SETTING_HUD_EFFECT], g_eSettings[SETTING_HUD_FXTIME], g_eSettings[SETTING_HUD_HOLDTIME], g_eSettings[SETTING_HUD_FADEIN], g_eSettings[SETTING_HUD_FADEOUT])
    ShowSyncHudMsg(0, iHudObject, "%s%s", szName, szMessage)

    g_iHudSlot ++
    g_iHudCurrentY += HUD_Y_STEP
    if ( g_iHudCurrentY > HUD_Y_MAX )
    {
        g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
        g_iHudSlot = 0
    }
}

stock throneSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
        case SOUND_FLUSH:       ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_FLUSH], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_FLUSH])), szSample, charsmax(szSample))
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock throneReset()
{
    new eThrone[THRONE]
    for ( new i = 0; i < g_iThrone; i ++ )
    {
        ArrayGetArray(g_aThrone, i, eThrone)
        eThrone[THRONE_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aThrone, i, eThrone)
    }

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        g_ePlayerData[id][PDATA_NEXT_THRONE] = 0.0
        g_ePlayerData[id][PDATA_NEXT_CHECK] = 0.0
    }
}

stock throneGet(eThrone[THRONE], iEnt)
{
    if ( !isThrone(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, THRONE_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iThrone )
        return -1

    ArrayGetArray(g_aThrone, iItem, eThrone)
    return iItem
}

stock bool:isThrone(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == THRONE_KEY
}

stock throneKill(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_MODEL:
        {
            precache_model(szValue)
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
        case DTYPE_ARRAY_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                ArrayPushCell(aOutput[0], precache_model(szValue))
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_THRONE_ACTION] )
    {
        new eThrone[THRONE]
        for ( new i = 0; i < g_iThrone; i ++ )
        {
            ArrayGetArray(g_aThrone, i, eThrone)
            if ( eThrone[THRONE_FLAGS] & FLAG_SHOW )
                continue

            throneSelect(eThrone, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_THRONE_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_THRONE_ACTION] )
    {
        new eThrone[THRONE]
        for ( new i = 0; i < g_iThrone; i ++ )
        {
            ArrayGetArray(g_aThrone, i, eThrone)
            if ( eThrone[THRONE_FLAGS] & FLAG_SHOW )
                continue

            throneSelect(eThrone, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_THRONE_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
}

stock EnableThrone()
{
    g_iFwdEmitSound = register_forward(FM_EmitSound, "fwdEmitSound")
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
    EnableHamForward(g_iFwdPostThink)
}

stock DisableThrone()
{
    unregister_forward(FM_EmitSound, g_iFwdEmitSound)
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
    DisableHamForward(g_iFwdPostThink)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}





