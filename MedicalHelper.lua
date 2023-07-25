require "lib.moonloader"
local vkeys, inicfg, imgui = require 'lib.vkeys', require 'inicfg', require 'imgui'
imgui.ToggleButton = require('imgui_addons').ToggleButton

local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

script_name("MedicalHelper")
script_version("4.0.1.b")
local sver = "4.0.1.b"

local enable_autoupdate = true -- false to disable auto-update + disable sending initial telemetry (server, moonloader version, script version, samp nickname, virtual volume serial number)
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage('{ff2e2e}[MedicalHelper] {ffffff}���������� ����������. ������� ���������� c {ff2e2e}'..thisScript().version..'{ffffff} �� {ff2e2e}'..updateversion, m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('{ffffff}��������� %d �� %d.', p, q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('{ffffff}�������� ���������� ���������.')sampAddChatMessage('{ff2e2e}[MedicalHelper] {ffffff}���������� ���������!', m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage('{ff2e2e}[MedicalHelper] {ffffff}���������� ������ ��������. ������ ������ ������..', m)update=false end end end)end,b)else update=false;print('{ffffff}v. '..thisScript().version..': ���������� �� ���������.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('{ffffff}v. '..thisScript().version..': ��������� ���������� �� �������. ��������� ���������� �������������� �� '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('{ffffff}v. '..thisScript().version..': ��������� ������. ����� �� �������� �������� ����������. ��������� ���������� �������������� �� '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/zmrch/medicalhelper_upd/main/medicalhelper_upd.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/zmrch/medicalhelper_upd"
        end
    end
end

local variable = {
		antiflood			= 0,
		pstats				= 0, 
		mcheck				= false,
		myadds				= 0,
		selected_cmd		= 1,
		check_zp			= 0,
		value_zp			= 0,
		partner				= "",
		sname				= "",
		rptimer				= 0,
}

local medWork = {
		heal_all			= 0,
		medcard_all			= 0, 
		heal_post			= 0,
		medcard_post		= 0,
}

local t1, mt, Player, veh_pid = {}, {}, {}, {}

local currentKey		= {"",{}}
local cb_RBUT			= imgui.ImBool(false)
local cb_x1				= imgui.ImBool(false)
local cb_x2				= imgui.ImBool(false)
local isHotKeyDefined	= false

local lower, sub, char, upper = string.lower, string.sub, string.char, string.upper
local concat = table.concat
local lu_rus, ul_rus = {}, {}
local r = { mouse = false, ShowClients = false, ShowCMD = false, id = 0, nick = "", dir = "", dialog = 0 }

for i = 192, 223 do
    local A, a = char(i), char(i + 32)
    ul_rus[A] = a
    lu_rus[a] = A
end

local E, e = char(168), char(184)
ul_rus[E] = e
lu_rus[e] = E

local venick = {
	p_id = 0,
	p_nick = "", 
}

local sampfuncsNot = [[
 �� ��������� ���� SAMPFUNCS.asi � ����� ����, ���������� ����
 ������� �� ������� �����������.

 ��� ������� ��������:
 1. �������� ����;
 2. ��������� ������������ ��������� ��� � �� ���������� ������� ����� ���� � ����������.
 (��������� ����������: �������� Windows, McAfree, Avast, 360 Total � ������.)
 3. ����������� ��������� ��������� �������.

 ���� ���� ��������, ������� ������ ���������� ������. 
]]

local errorText = [[
	[!] ��������! 
 �� ���������� ��������� ������ ����� ��� ������ �������,
 � ��������� ����, ������ �������� ��������.
 ������ �������������� ������:
	%s

 ��� ������� ��������:
 1. �������� ����;
 2. ��������� ������������ ��������� ��� � �� ���������� ������� ����� ���� � ����������.
 (��������� ����������: �������� Windows, McAfree, Avast, 360 Total � ������.)
 3. ����������� ��������� ��������� �������.

 ���� ���� ��������, ������� ������ ���������� ������.
]]

local files = {
	"/lib/imgui.lua",
	"/lib/samp/events.lua",
	"/lib/rkeys.lua",
	"/lib/faIcons.lua",
	"/lib/crc32ffi.lua",
	"/lib/bitex.lua",
	"/lib/MoonImGui.dll",
	"/lib/matrix3x3.lua"
}

local nofiles = {}
for i,v in ipairs(files) do
	if not doesFileExist(getWorkingDirectory()..v) then
		table.insert(nofiles, v)
	end
end

local ffi = require 'ffi'
ffi.cdef [[
		typedef int BOOL;
		typedef unsigned long HANDLE;
		typedef HANDLE HWND;
		typedef const char* LPCSTR;
		typedef unsigned UINT;
		
        void* __stdcall ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show_cmd);
        uint32_t __stdcall CoInitializeEx(void*, uint32_t);
		
		BOOL ShowWindow(HWND hWnd, int  nCmdShow);
		HWND GetActiveWindow();
		
		
		int MessageBoxA(
		  HWND   hWnd,
		  LPCSTR lpText,
		  LPCSTR lpCaption,
		  UINT   uType
		);
		
		short GetKeyState(int nVirtKey);
		bool GetKeyboardLayoutNameA(char* pwszKLID);
		int GetLocaleInfoA(int Locale, int LCType, char* lpLCData, int cchData);
  ]]

local shell32 = ffi.load 'Shell32'
local ole32 = ffi.load 'Ole32'
ole32.CoInitializeEx(nil, 2 + 4)

if not doesFileExist(getGameDirectory().."/SAMPFUNCS.asi") then
	ffi.C.ShowWindow(ffi.C.GetActiveWindow(), 6)
	ffi.C.MessageBoxA(0, sampfuncsNot, "MedicalHelper", 0x00000030 + 0x00010000) 
end

if #nofiles > 0 then
	ffi.C.ShowWindow(ffi.C.GetActiveWindow(), 6)
	ffi.C.MessageBoxA(0, errorText:format(table.concat(nofiles, "\n\t\t")), "MedicalHelper", 0x00000030 + 0x00010000) 
end

local res, sampev = pcall(require, 'lib.samp.events')
assert(res, "���������� SAMP Event �� �������")
local res, imgui = pcall(require, "imgui")
assert(res, "���������� Imgui �� �������")
local res, fa = pcall(require, 'faIcons')
assert(res, "���������� faIcons �� �������")
local res, rkeys = pcall(require, 'rkeys')
assert(res, "���������� Rkeys �� �������")

skins = {70, 219, 274, 275, 276, 308}

local CarList = {
	[400] = '[N] "Landstalker"',
	[401] = '[D] "Bravura"',
	[402] = '[A] "Buffalo"',
	[403] = '[S] "Linerunner"',
	[404] = '[N] "Perenniel"',
	[405] = '[D] "Sentinel"',
	[406] = '[S] "Dumper"',
	[407] = '[S] "Firetruck"',
	[408] = '[S] "Trashmaster"',
	[409] = '[S] "Stretch"',
	[410] = '[S] "Manana"',
	[411] = '[A] "Infernus"',
	[412] = '[D] "Voodoo"',
	[413] = '[S] "Pony"',
	[414] = '[S] "Mule"',
	[415] = '[A] "Cheetah"',
	[416] = '[S] "Ambulance"',
	[417] = '[��������] "Leviathan"',
	[418] = '[C] "Moonbeam"',
	[419] = '[C] "Esperanto"',
	[420] = '[S] "Taxi"',
	[421] = '[C] "Washington"',
	[422] = '[D] "Bobcat"',
	[423] = '[S] "Mr. Whoopee"',
	[424] = '[A] "BF Injection"',
	[425] = '[��������] "Hunter"',
	[426] = '[D] "Premier"',
	[427] = '[S] "Enforcer"',
	[428] = '[S] "Securicar"',
	[429] = '[A] "Banshee"',
	[430] = '[�����] "Predator"',
	[431] = '[S] "Bus"',
	[432] = '[S] "Rhino"',
	[433] = '[S] "Barracks"',
	[434] = '[A] "Hotknife"',
	[435] = '[�������] "Article Trailer"',
	[436] = '[N] "Previon"',
	[437] = '[S] "Coach"',
	[438] = '[S] "Cabbie"',
	[439] = '[N] "Stallion"',
	[440] = '[S] " Rumpo"',
	[441] = '[S] "RC Bandit"',
	[442] = '[S] "Romero"',
	[443] = '[S] "Packer"',
	[444] = '[S] "Monster"',
	[445] = '[C] "Admiral"',
	[446] = '[����] "Squallo"',
	[447] = '[��������] "Seasparrow"',
	[448] = '[S] "Pizzaboy"',
	[449] = '[S] "Tram"',
	[450] = '[�������] "Article Trailer 2"',
	[451] = '[A] "Turismo"',
	[452] = '[�����] "Speeder"',
	[453] = '[�����] "Reefer"',
	[454] = '[����] "Tropic"',
	[455] = '[S] "Flatbed"',
	[456] = '[S] "Yankee"',
	[457] = '[S] Caddy',
	[458] = '[N] "Solair"',
	[459] = '[S] "Topfun Van"',
	[460] = '[�������] "Skimmer"',
	[461] = '[C] "PCJ-600"',
	[462] = '[�����] "Faggio"',
	[463] = '[B] "Freeway"',
	[464] = '[�����������] "RC Baron"',
	[465] = '[�����������] "RC Raider"',
	[466] = '[N] "Glendale"',
	[467] = '[D] "Oceanic"',
	[468] = '[B] "Sanchez"',
	[469] = '[��������] "Sparrow"',
	[470] = '[S] "Patriot"',
	[471] = '[B] "Quad"',
	[472] = '[�����] "Coastguard"',
	[473] = '[�����] "Dinghy"',
	[474] = '[D] "Hermes"',
	[475] = '[N] "Sabre"',
	[476] = '[�������] "Rustler"',
	[477] = '[C] "ZR-350"',
	[478] = '[N] "Walton"',
	[479] = '[N] "Regina"',
	[480] = '[B] "Comet"',
	[481] = '[S] "BMX"',
	[482] = '[S] "Burrito"',
	[483] = '[S] "Camper"',
	[484] = '[����] "Marquis"',
	[485] = '[S] "Baggage"',
	[486] = '[S] "Dozer"',
	[487] = '[��������] "Maverick"',
	[488] = '[��������] "SAN News Maverick"',
	[489] = '[C] "Rancher"',
	[490] = '[S] "FBI Rancher"',
	[491] = '[C] "Virgo"',
	[492] = '[N] "Greenwood"',
	[493] = '[����] "Jetmax"',
	[494] = '[A] "Hotring Racer"',
	[495] = '[A] "Sandking"',
	[496] = '[D] "Blista Compact"',
	[497] = '[��������] "Police Maverick"',
	[498] = '[S] "Boxville"',
	[499] = '[S] "Benson"',
	[500] = '[S] "Mesa"',
	[501] = '[�����������] "RC Goblin"',
	[502] = '[A] "Hotring Racer"',
	[503] = '[A] "Hotring Racer B"',
	[504] = '[S] "Bloodring Banger"',
	[505] = '[C] "Rancher Lure"',
	[506] = '[A] "Super GT"',
	[507] = '[D] "Elegant"',
	[508] = '[S] "Journey"',
	[509] = '[S] "Bike"',
	[510] = '[S] "Mountain Bike"',
	[511] = '[�������] "Beagle"',
	[512] = '[�������] "Cropduster"',
	[513] = '[�������] "Stuntplane"',
	[514] = '[S] "Tanker"',
	[515] = '[S] "Roadtrain"',
	[516] = '[N] "Nebula "',
	[517] = '[N] "Majestic"',
	[518] = '[N] "Buccaneer"',
	[519] = '[�������] "Shamal"',
	[520] = '[�������] "Hydra"',
	[521] = '[B] "FCR-900"',
	[522] = '[A] "NRG-500"',
	[523] = '[S] "HPV1000"',
	[524] = '[S] "Cement Truck"',
	[525] = '[S] "Towtruck"',
	[526] = '[N] "Fortune"',
	[527] = '[N] "Cadrona"',
	[528] = '[S] "FBI Truck"',
	[529] = '[D] "Willard"',
	[530] = '[S] "Forklift"',
	[531] = '[S] "Tractor"',
	[532] = '[S] "Combine Harvester"',
	[533] = '[C] "Feltzer"',
	[534] = '[C] "Remington"',
	[535] = '[B] "Slamvan"',
	[536] = '[D] "Blade"',
	[537] = '[S] "Freight (Train)"',
	[538] = '[S] " Brownstreak (Train)"',
	[539] = '[S] "Vortex"',
	[540] = '[D] "Vincent"',
	[541] = '[N] "Bullet"',
	[542] = '[N] "Clover"',
	[543] = '[N] "Sadler"',
	[544] = '[S] "Firetruck LA"',
	[545] = '[B] "Hustler"',
	[546] = '[N] "Intruder"',
	[547] = '[N] "Primo"',
	[548] = '[��������] "Cargobob"',
	[549] = '[N] "Tampa"',
	[550] = '[D] "Sunrise"',
	[551] = '[D] "Merit"',
	[552] = '[S] "Utility Van"',
	[553] = '[�������] "Nevada"',
	[554] = '[C] "Yosemite"',
	[555] = '[C] "Windsor"',
	[556] = '[S] "Monster "A""',
	[557] = '[S] "Monster "B""',
	[558] = '[B] "Uranus"',
	[559] = '[B] "Jester (Supra)"',
	[560] = '[B] "Sultan"',
	[561] = '[C] "Stratum"',
	[562] = '[B] "Elegy"',
	[563] = '[��������] "Raindance"',
	[564] = '[S] "RC Tiger"',
	[565] = '[B] "Flash"',
	[566] = '[D] "Tahoma"',
	[567] = '[N] "Savanna"',
	[568] = '[S] "Bandito"',
	[569] = '[S] "Freight Flat Trailer (Train)"',
	[570] = '[S] "Streak Trailer (Train)"',
	[571] = '[S] "Kart"',
	[572] = '[S] "Mower"',
	[573] = '[S] "Dune"',
	[574] = '[S] "Sweeper"',
	[575] = '[D] "Broadway"',
	[576] = '[D] "Tornado"',
	[577] = '[�������] "AT400"',
	[578] = '[S] "DFT-30"',
	[579] = '[C] "Huntley"',
	[580] = '[C] "Stafford"',
	[581] = '[C] "BF-400"',
	[582] = '[S] "Newsvan"',
	[583] = '[S] "Tug"',
	[584] = '[�������] "Petrol Trailer"',
	[585] = '[D] "Emperor"',
	[586] = '[C] "Wayfarer"',
	[587] = '[B] "Euros"',
	[588] = '[S] "Hotdog"',
	[589] = '[C] "Club"',
	[590] = '[S] "Freight Box Trailer (Train)"',
	[591] = '[S] "Article Trailer 3"',
	[592] = '[�������] "Andromada"',
	[593] = '[�������] "Dodo"',
	[594] = '[S] "RC Cam"',
	[595] = '[�����] "Launch"',
	[596] = '[S] "Police Car (LSPD)"',
	[597] = '[S] "Police Car (SFPD)"',
	[598] = '[S] "Police Car (LVPD)"',
	[599] = '[S] "Police Ranger"',
	[600] = '[D] "Picador"',
	[601] = '[S] "S.W.A.T. (Swatvan)"',
	[602] = '[B] "Alpha"',
	[603] = '[C] "Phoenix"',
	[604] = '[S] "Glendale Shit"',
	[605] = '[S] "Sadler Shit"',
	[606] = '[�������] "Baggage Trailer "A"',
	[607] = '[�������] "Baggage Trailer "B"',
	[608] = '[S] "Tug Stairs Trailer"',
	[609] = '[S] "Boxville"',
	[610] = '[�������] "Farm Trailer"',
	[611] = '[�������] "Utility Trailer"'
}
			
local adress = {
	config					= string.format("%s\\moonloader\\config", getGameDirectory()),
	folder					= string.format("%s\\moonloader\\config\\MedicalHelper", getGameDirectory()),
	chatlog					= string.format("%s\\moonloader\\config\\MedicalHelper\\chlog.txt", getGameDirectory()),
	col						= string.format("MedicalHelper\\Color.ini")
}

local col = inicfg.load({
	Colors = {
		col_fchat			= 0xFFFFFF,
		col_sms				= 0xFFFFFF,
		col_sqchat			= 0xFFFFFF,
		active_fchat		= false,
		active_sms			= false,
		active_sqchat		= false,
		fchat1				= 255, fchat2 = 255, fchat3 = 255,
		sms1				= 255, sms2 = 255, sms3 = 255,
		sqchat1				= 255, sqchat2 = 255, sqchat3 = 255,
		active_dep			= false,
		col_dep				= 0xFFFFFF,
		dep1				= 255, dep2 = 255, dep3 = 255,
	},
	Style = {
		round				= 10.0,
		colorW				= 2182156561,
		colorT				= 4294967295,
	}
}, adress.col)

local coords = {
	buf_x_stats			= 992,
	buf_y_stats			= 172,
	buf_x_pluschat		= 290,
	buf_y_pluschat		= 545,
	buf_x_select		= 765,
	buf_y_select		= 291, }

local buffer = {
	num_tag				= imgui.ImInt(0),
	buf_Clist			= 0,
	buf_tag				= "", 
	buf_ru_nick			= "",
	buf_nick			= imgui.ImBuffer(64), -- ���������������� ��� (��)
	stats_imgui			= imgui.ImBool(true), -- ���.���� �� �����������
	sstats				= imgui.ImBool(true), -- ��������� ����������� ���������� ��������� � ���. ����
	smap				= imgui.ImBool(true), -- ��������� ����������� �������������� � ���. ����
	clmenu				= imgui.ImBool(false),
	clmenu_nicks		= imgui.ImBool(false),
	pluschat			= imgui.ImBool(false),
	nh_menu				= imgui.ImBool(false),
	pnumber				= imgui.ImInt(0),
	namenumber			= imgui.ImInt(0),
	actg				= imgui.ImBool(true),
	OffA				= imgui.ImBool(false),
	OffG				= imgui.ImBool(false),
	OffC				= imgui.ImBool(false),
	sstr				= imgui.ImBool(true),
	OffAdm				= imgui.ImBool(false),
	buf_OnTag			= imgui.ImBool(false),
	Offcl				= imgui.ImBool(false),
}

local argbW				= col.Style.colorW
local argbT				= col.Style.colorT
local colorW			= imgui.ImFloat4(imgui.ImColor(argbW):GetFloat4())
local colorT			= imgui.ImFloat4(imgui.ImColor(argbT):GetFloat4())
local sRound			= imgui.ImFloat(col.Style.round)
local posX, posY		= coords.buf_x_stats, coords.buf_y_stats
local posXs, posYs		= coords.buf_x_select, coords.buf_y_select
local posXp, posYp		= coords.buf_x_pluschat, coords.buf_y_pluschat
local fchat_check		= imgui.ImBool(col.Colors.active_fchat)
local sms_check			= imgui.ImBool(col.Colors.active_sms)
local sqchat_check		= imgui.ImBool(col.Colors.active_sqchat)
local dep_check			= imgui.ImBool(col.Colors.active_dep)
local psize				= imgui.ImInt(0)
local psizeX, psizeY	= 955, psize.v

local fchat					= imgui.ImFloat3(col.Colors.fchat3 / 255, col.Colors.fchat2 / 255, col.Colors.fchat1 / 255)
local sms					= imgui.ImFloat3(col.Colors.sms3 / 255, col.Colors.sms2 / 255, col.Colors.sms1 / 255)
local sqchat				= imgui.ImFloat3(col.Colors.sqchat3 / 255, col.Colors.sqchat2 / 255, col.Colors.sqchat1 / 255)
local dep					= imgui.ImFloat3(col.Colors.dep3 / 255, col.Colors.dep2 / 255, col.Colors.dep1 / 255)

local chgName				= {}
chgName.inp					= imgui.ImBuffer(100)
chgName.inp2				= imgui.ImInt(2)
chgName.tag					= { u8'������� ���', u8'��������� SFMC', u8'������ SFMC', u8'��������� SFMC', u8'���.������� SFMC', u8'������ SFMC', u8'��������� ASGH', u8'��������� ASGH', u8'���.���.ASGH', u8'���.ASGH', u8'����.LVH', u8'������� ����.LVH', u8'���.���.LVH', u8'���.LVH', }
local list_tag				= { u8'������� ���', u8'��������� SFMC', u8'������ SFMC', u8'��������� SFMC', u8'���.������� SFMC', u8'������ SFMC', u8'��������� ASGH', u8'��������� ASGH', u8'���.���.ASGH', u8'���.ASGH', u8'����.LVH', u8'������� ����.LVH', u8'���.���.LVH', u8'���.LVH', }
chgName.uname				= {}
chgName.stats				= { u8("���"), u8("���"), u8("���"), u8("���"), 0, u8("���"), }
chgName.clist				= { 33, 19, 19, 4, 4, 12, 23, 23, 4, 12, 21, 21, 4, 12, }
local list_clist			= { 33, 19, 19, 4, 4, 12, 23, 23, 4, 12, 21, 21, 4, 12, }

local Settings = {
	Tag					= 0,
	Clist				= 0,
	UserName			= '',
	Show_Stats			= true,
	Show_smap			= true,
	Show_sstats			= true,
	Plus_Chat			= false,
	Plus_Size			= 70,
	Plus_Number			= 4,
	Autoclist			= true,
	OffAdds				= false,
	OffGov				= false,
	select_streets		= false,
	select_name			= 0,
	x_stats				= 992,
	y_stats				= 172,
	x_pluschat			= 290,
	y_pluschat			= 545,
	x_select			= 765,
	y_select			= 291,
	OffAdmins			= false,
	OnTag				= false,
	bTag				= '',
	OffClue				= false,
	Offclmenu			= false,

--	Plus_Adds			= false,
--	Plus_Radio			= false,

--	today				= os.date("%a"),
--	week				= 1,
--	hour				= os.date("%H"),
	
}

local CL = {
	COLOR_WHITE				= 0xFFFFFF,
	COLOR_GRAY				= 0xa6bdd7,
	COLOR_RED				= 0xff2e2e,
	COLOR_GREEN				= 0x00FF00,
	COLOR_ADM				= 0xFF6347, }

local but = {}
but.select_menu				= {true, false, false, false, false}
but.select_settings			= {true, false, false, false}
but.select_button			= {false, false, false, false, false, false, false, false, false, false, false}
but.commands_settings		= {true, false}
but.cset					= 1
but.nset					= 1


local achsex, achsex2 = "", ""
function chsex()
	if chgName.stats[2] == "�������" then 
		achsex = "�"
		achsex2 = "��"
	else 
		achsex = ""
		achsex2 = ""
	end
end

	if Sex == "�������" then
		a = "�"
		la = "��"
	else
		a = ""
		la = ""
	end

local isFontChange
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })

function imgui.BeforeDrawFrame()
	if not isFontChange then
		isFontChange = true
		local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
		local font_config = imgui.ImFontConfig()
		font_config.MergeMode = true
		imgui.GetIO().Fonts:Clear()

		imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\Arial.ttf', 13.0, nil, glyph_ranges)
		fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 13.0, font_config, fa_glyph_ranges)
  
		fsStil = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\Arial.ttf', 14.0, nil, glyph_ranges)
		fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 17.0, font_config, fa_glyph_ranges)

      imgui.RebuildFonts()
	end
end

vkeys.key_names[vkeys.VK_RBUTTON] = "RBut"
vkeys.key_names[vkeys.VK_XBUTTON1] = "XBut1"
vkeys.key_names[vkeys.VK_XBUTTON2] = 'XBut2'
vkeys.key_names[vkeys.VK_NUMPAD1] = 'Num 1'
vkeys.key_names[vkeys.VK_NUMPAD2] = 'Num 2'
vkeys.key_names[vkeys.VK_NUMPAD3] = 'Num 3'
vkeys.key_names[vkeys.VK_NUMPAD4] = 'Num 4'
vkeys.key_names[vkeys.VK_NUMPAD5] = 'Num 5'
vkeys.key_names[vkeys.VK_NUMPAD6] = 'Num 6'
vkeys.key_names[vkeys.VK_NUMPAD7] = 'Num 7'
vkeys.key_names[vkeys.VK_NUMPAD8] = 'Num 8'
vkeys.key_names[vkeys.VK_NUMPAD9] = 'Num 9'
vkeys.key_names[vkeys.VK_MULTIPLY] = 'Num *'
vkeys.key_names[vkeys.VK_ADD] = 'Num +'
vkeys.key_names[vkeys.VK_SEPARATOR] = 'Separator'
vkeys.key_names[vkeys.VK_SUBTRACT] = 'Num -'
vkeys.key_names[vkeys.VK_DECIMAL] = 'Num .Del'
vkeys.key_names[vkeys.VK_DIVIDE] = 'Num /'
vkeys.key_names[vkeys.VK_LEFT] = 'Ar.Left'
vkeys.key_names[vkeys.VK_UP] = 'Ar.Up'
vkeys.key_names[vkeys.VK_RIGHT] = 'Ar.Right'
vkeys.key_names[vkeys.VK_DOWN] = 'Ar.Down'

cmdBind = {
	[1] = {
		cmd	= "/mh",
		key = {},
		desc = "������� ���� �������",
		rank = 1,
		rb = false
	},
	[2] = {
		cmd = "/clmenu",
		key = {},
		desc = "������� ��� ������ ������������� ����",
		rank = 1,
		rb = false
	},
	[3] = {
		cmd = "/r",
		key = {},
		desc = "������� ��� ������ ����� � ����� [���� �������]",
		rank = 1,
		rb = false
	},
	[4] = {
		cmd = "/rb",
		key = {},
		desc = "������� ��� ��������� ����� ��������� � �����.",
		rank = 1,
		rb = false
	},
	[5] = {
		cmd = "/mb",
		key = {},
		desc = "����������� ������� /members",
		rank = 1,
		rb = false
	},
	[6] = {
		cmd = "/hl",
		key = {},
		desc = "������� � �������������� �� ����������",
		rank = 1,
		rb = false
	},
	[7] = {
		cmd = "/post",
		key = {},
		desc = "������ � ���������� �����. ����� ���������� � ������.",
		rank = 2,
		rb = false
	},
	[8] = {
		cmd = "/mc",
		key = {},
		desc = "������ ��� ���������� ���.�����",
		rank = 2,
		rb = false
	},
	[9] = {
		cmd = "/narko",
		key = {},
		desc = "������� �� ����������������",
		rank = 4,
		rb = false
	},
	[10] = {
		cmd = "/osm",
		key = {},
		desc = "���������� ����������� ������",
		rank = 5,
		rb = false
	},
	[11] = {
		cmd = "/sob",
		key = {},
		desc = "���� ������������� � ���������",
		rank = 5,
		rb = false
	},
	[12] = {
		cmd = "/fmute",
		key = {},
		desc = "������ ��� ����������",
		rank = 9,
		rb = false
	},
	[13] = {
		cmd = "/funmute",
		key = {},
		desc = "����� ��� ����������",
		rank = 9,
		rb = false
	},
	[14] = {
		cmd = "/gr",
		key = {},
		desc = "�������� ���� (���������) ����������",
		rank = 9,
		rb = false
	},
	[15] = {
		cmd = "/ts",
		key = {},
		desc = "������� �������� � �������������� ������ /time",
		rank = 1,
		rb = false
	},
}

editKey = false
keysList = {}

local BlockKeys = {{vkeys.VK_T}, {vkeys.VK_F6}, {vkeys.VK_F8}, {vkeys.VK_RETURN}, {vkeys.VK_OEM_3}, {vkeys.VK_LWIN}, {vkeys.VK_RWIN}}

rkeys.isBlockedHotKey = function(keys)
	local bool, hkId = false, -1
	for k, v in pairs(BlockKeys) do
	   if rkeys.isHotKeyHotKey(keys, v) then
		  bool = true
		  hkId = k
		  break
	   end
	end
	return bool, hkId
end

function rkeys.isHotKeyExist(keys)
local bool = false
	for i,v in ipairs(keysList) do
		if table.concat(v,"+") == table.concat(keys, "+") then
			if #keys ~= 0 then
				bool = true
				break
			end
		end
	end
	return bool
end

function unRegisterHotKey(keys)
	for i,v in ipairs(keysList) do
		if v == keys then
			keysList[i] = nil
			break
		end
	end
	local listRes = {}
	for i,v in ipairs(keysList) do
		if #v > 0 then
			listRes[#listRes+1] = v
		end
	end
	keysList = listRes
end

-- saveData(rptext, "moonloader/config/MedicalHelper/roleplay.json")
function saveData(table, path)
	if doesFileExist(path) then os.remove(path) end
    local sfa = io.open(path, "w")
    if sfa then
        sfa:write(encodeJson(table))
        sfa:close()
    end
end

local buf_note = imgui.ImBuffer(51200)
local buf_note_name = imgui.ImBuffer(256)
local table_note = {}
local buf_rp = imgui.ImBuffer(51200)
local buf_rp_name = imgui.ImBuffer(42)
local rptext = {}

local buf_table_note = {
	[1] = { name = "���� 1", text = "������ ����" },
	[2] = { name = "���� 2", text = "������ ����" },
	[3] = { name = "���� 3", text = "������ ����" },
	[4] = { name = "���� 4", text = "������ ����" },
	[5] = { name = "���� 5", text = "������ ����" },
	[6] = { name = "���� 6", text = "������ ����" },
	[7] = { name = "���� 7", text = "������ ����" },
	[8] = { name = "���� 8", text = "������ ����" },
	[9] = { name = "���� 9", text = "������ ����" },
	[10] = { name = "���� 10", text = "������ ����" },
	[11] = { name = "���� 11", text = "������ ����" },
	[12] = { name = "���� 12", text = "������ ����" },
	[13] = { name = "���� 13", text = "������ ����" },
	[14] = { name = "���� 14", text = "������ ����" },
	[15] = { name = "���� 15", text = "������ ����" },
	[16] = { name = "���� 16", text = "������ ����" },
	[17] = { name = "���� 17", text = "������ ����" },
	[18] = { name = "���� 18", text = "������ ����" },
	[19] = { name = "���� 19", text = "������ ����" },
	[20] = { name = "���� 20", text = "������ ����" },
	[21] = { name = "���� 21", text = "������ ����" },
	[22] = { name = "���� 22", text = "������ ����" },
	[23] = { name = "���� 23", text = "������ ����" },
	[24] = { name = "���� 24", text = "������ ����" },
	[25] = { name = "���� 25", text = "������ ����" },
	[26] = { name = "���� 26", text = "������ ����" },
	[27] = { name = "���� 27", text = "������ ����" },
	[28] = { name = "���� 28", text = "������ ����" },
	[29] = { name = "���� 29", text = "������ ����" },
	[30] = { name = "���� 30", text = "������ ����" },
	[31] = { name = "���� 31", text = "������ ����" },
	[32] = { name = "���� 32", text = "������ ����" },
	[33] = { name = "���� 33", text = "������ ����" },
	[34] = { name = "���� 34", text = "������ ����" },
	[35] = { name = "���� 35", text = "������ ����" },
	[36] = { name = "���� 36", text = "������ ����" },
	[37] = { name = "���� 37", text = "������ ����" },
	[38] = { name = "���� 38", text = "������ ����" },
	[39] = { name = "���� 39", text = "������ ����" },
	[40] = { name = "���� 40", text = "������ ����" },
	[41] = { name = "���� 41", text = "������ ����" },
	[42] = { name = "���� 42", text = "������ ����" },
	[43] = { name = "���� 43", text = "������ ����" },
	[44] = { name = "���� 44", text = "������ ����" },
	[45] = { name = "���� 45", text = "������ ����" },
	[46] = { name = "���� 46", text = "������ ����" },
	[47] = { name = "���� 47", text = "������ ����" },
	[48] = { name = "���� 48", text = "������ ����" },
	[49] = { name = "���� 49", text = "������ ����" },
	[50] = { name = "���� 50", text = "������ ����" },
}

local buf_rptext = {
	[1] = {
		name = "�������� ����",
		text = "{wait:250}\n/do �� ����� ������� ���.�����\n{wait:1500}\n/me ������{sex} �������� �������� � �������{sex} ��������\n{wait:1500}\n/me �����{sex} ������ ���� � �������{sex} ��������  ������ � ���������\n{wait:1100}\n/heal {pID}"
	},
	[2] = {
		name = "�������",
		text = "{wait:250}\n/me ����������� ��������{sex} ��������� ��������\n{wait:1500}\n/do �� ����� ������� ���.�����\n{wait:1500}\n� ��� �������. � ������ ��� �����.\n{wait:1500}\n/me ������{sex} �� ���.����� ����� ��������\n{wait:1500}\n/me �������{sex} ����� ��������\n{wait:1100}\n/heal {pID}"
	},
	[3] = {
		name = "������",
		text = "{wait:250}\n/do �� ����� ������� ���.�����\n{wait:1500}\n/me ��������{sex} ��������\n{wait:1500}\n� ��� ������� ������. � ������ ��� ������� ������ ���.\n{wait:1500}\n/me ������{sex} ������� �� ���.�����\n{wait:1500}\n/me �������{sex} ���������\n{wait:1100}\n/heal {pID}"
	},
	[4] = {
		name = "����� / ��������",
		text = "{wait:250}\n/me ��������{sex} ��������\n{wait:1500}\n/do �� ����� ������� ��������\n{wait:1500}\n/me ������{sex} ����� � ������{sex} ����� � ��������\n{wait:1500}\n/me ����{sex} ��������� ������� �������� �������������\n{wait:1100}\n/heal {pID}"
	},
	[5] = {
		name = "����������",
		text = "{wait:250}\n/me ������{sex} �� ����� ������� � ����������\n{wait:1500}\n/me �����{sex} ���� �� ������� � ������\n{wait:1500}\n/todo ������� ��� * ������� ������ � ����������\n{wait:1100}\n/heal {pID}"
	},
	[6] = {
		name = "���� � ������",
		text = "{wait:250}\n� ������ ��� �������� �����.\n{wait:1500}\n/do �� ����� ������� ���.�����\n{wait:1500}\n/me ������{sex} ��������� �������� ����� �� ���.�����\n{wait:1500}\n/me �������{sex} ���������� �� ����������\n{wait:1500}\n/me �������{sex} ���������� � ��������� ��������\n{wait:1100}\n/heal {pID}"
	},
	[7] = {
		name = "��������",
		text = "{wait:250}\n� ������ ��� ����� ����� � ������� ���� �������.\n{wait:1500}\n/do �� ����� ������� ���.�����\n{wait:1500}\n/me ������{sex} �������� ���������� ������\n{wait:1500}\n/me �������{sex} �������� �����\n{wait:1500}\n/me ������{sex} �� ������� ����� � ����� � �������{sex} ������\n{wait:1500}\n/me �������{sex} �������� ������\n{wait:1100}\n/heal {pID}"
	},
	[8] = {
		name = "����������������",
		text = "{wait:250}\n/todo C������ ���� � ����� * ��������� ����\n{wait:1500}\n/me �������{sex} ���� ��������� �����\n{wait:1500}\n/me ������{sex} �������� �� ������ � �����\n{wait:1500}\n/me ����{sex} ��������� ����������� � ����{sex} ����\n{wait:1500}\n/me �����{sex} ���� �� ���� � ���������{sex} ��������� �����\n{wait:1100}\n/healdisease {pID}"
	},
	[9] = {
		name = "�����",
		text = "{wait:250}\n������ � ������ ��� �������� ��������.\n{wait:1500}\n� ����� ������ ��� �������.\n{wait:1500}\n���������� ���������� ����� �� ���� ���� � ���.\n{wait:1500}\n/me ������{sex} ������ ��������\n{wait:1500}\n/me ������{sex} ������� � �����\n{wait:1500}\n/todo ������������ * �������� ������ ����� �����\n{wait:1500}\n/me ����{sex} ������� �������� ��������\n{wait:1500}\n/todo ������ ���������� * �������� ������\n{wait:1500}\n/seeme �������{sex} ������ ��������\n{wait:1100}\n/healdisease {pID}"
	},
	[10] = {
		name = "�������",
		text = "{wait:250}\n/do � ����� ����� ���������\n{wait:1500}\n������� ���� � ��������� �����.\n{wait:1500}\n/me ��������{sex} ������ ��������\n{wait:1500}\n/todo � ��� ����� � ������ * ������ ���������\n{wait:1500}\n/me �������{sex} ������ �� ����������� � �������� ������ �����\n{wait:1500}\n/me �������{sex} �������� ������ � ��������\n{wait:1100}\n/healdisease {pID}"
	},
	[11] = {
		name = "����������",
		text = "{wait:250}\n/me ������{sex} �� �������� �������� ��������������� ����\n{wait:1500}\n/me �������{sex} ��������� �������� �����. ����\n{wait:1500}\n/me �������{sex} ��������\n{wait:1100}\n/healdisease {pID}"
	},
	[12] = {
		name = "�����",
		text = "{wait:250}\n/me ��������{sex} ���� �������� � ���������{sex} ��������� �����\n{wait:1500}\n/me ������{sex} �� ����� ���� �������\n{wait:1500}\n/me �������{sex} ���������� ������� ������� ���� �����\n{wait:1100}\n/healdisease {pID}"
	},
	[13] = {
		name = "�������� ���������",
		text = "{wait:250}\n/me ������{sex} �� ����� ����� � ������ ��������������\n{wait:1500}\n/me ������{sex} �������� �� ������ � �����\n{wait:1500}\n/me ����{sex} �������� �������������\n{wait:1100}\n/healdisease {pID}"
	},
	[14] = {
		name = "����������",
		text = "{wait:250}\n/me ��������{sex} ����� ��������� ��������\n{wait:1500}\n/me ������{sex} ����� � �������{sex} ���� ����������\n{wait:1500}\n/do � ����� ������� ��������� ��������� ��������\n{wait:1500}\n/me ������{sex} ��������� � �������{sex} ��������\n{wait:1500}\n/todo �������� ���� �������� ����� ���������� * ����������� � �������� ����\n{wait:1100}\n/healdisease {pID}"
	},
	[15] = {
		name = "����������� ��������",
		text = "{wait:250}\n/b ��������� �� ���� � /anim > 4 > 26\n{wait:1500}\n/seeme �����{sex} ����� ��������� ��������\n{wait:1500}\n/me �����{sex2} �������� ���� �� ������������ ����\n{wait:1500}\n/try ����������� �������� ��������, ���������{sex} �������� �������\n{wait:250}\n{help:[������] - ��� ����������� �������� ������� ' �������� ������� '}\n{help:[�� ������] - ��� ����������� �������� ������� ' ������� '}"
	},
	[16] = {
		name = "�������� �������",
		text = "{wait:250}\n/me �������{sex} �������-������� � ������{sex} ������ ������������ ����������\n{wait:1500}\n/seeme ����������� ������{sex} ������, ���������� �� �����\n{wait:1500}\n/me ����{sex} �������� � ��������� ������ �������, ����� �� ���� ������������� �����\n{wait:1500}\n/me �������� ��������{sex} ���������� ����� ����� ������������ �����\n{wait:1500}\n/me ��������� �������{sex} ����� ��������\n{wait:1500}\n/me ���� ����������� ���� � ����, �������{sex} ��� �� ����������\n{wait:1500}\n/me �������{sex} ���� � ����� ���������� ���� � �������{sex} �� ����������\n{wait:1100}\n/healwound {pID}"
	},
	[17] = {
		name = "�������",
		text = "{wait:250}\n/me �������{sex} �������-������� � ������{sex} ������ ������������ ����������\n{wait:1500}\n/me ����������� ������{sex} ������, ���������� �� �����\n{wait:1500}\n/try ������{sex} �� ������ �������\n{wait:250}\n{help:[������] - ��� ����������� �������� ������� ' �������� ������� '}\n{help:[�� ������] - ��� ����������� �������� ������� ' ���� '}"
	},
	[18] = {
		name = "�������� �������",
		text = "{wait:250}\n/me ������{sex} ����� � ������� ���������������\n{wait:1500}\n/me ������{sex} �������������� � ����� � ������{sex} ��������\n{wait:1500}\n/me �������{sex} �����, ����� ���� �������{sex} �������\n{wait:1100}\n/healwound {pID}\n{wait:1100}\n/todo ������ ����� ����� �������� * ��������� ������� ��������"
	},
	[19] = {
		name = "����",
		text = "{wait:250}\n��� �������, ��� �������� ��� ���������. ����� ���� ����.\n{wait:1500}\n/me ������{sex} �� �������� ����� ����\n{wait:1500}\n/me �����{sex2} �� ����� ����� ���� � ������{sex2} �� ����������� ����������\n{wait:1500}\n/me �������{sex} �� ����� ����� ���������� ����\n{wait:1100}\n/healwound {pID}"
	},
	[20] = {
		name = "����",
		text = "{wait:250}\n�������� �� ����, ������ ������ ��� ���������.\n{wait:1500}\n/me ������{sex} �� ���.����� ������� � �����������������{sex} ���� ��������\n{wait:1500}\n/do ����������� ��� �������� ���������� ����� �� �����\n{wait:1500}\n/me ���� � ���� ������������� ���� � ����, �������{sex} ��� �� ����\n{wait:1500}\n/me �������{sex} ���������� ������� �� ����� ���\n{wait:1100}\n/healwound {pID}"
	},
	[21] = {
		name = "������������� �������",
		text = "{wait:250}\n/me ����������� ��������{sex} ������� �������������\n{wait:1500}\n/seeme ������{sex} ������ ��������� � �����\n{wait:1500}\n/me ������{sex} �������� � ����� � ����{sex} �������������� ��������\n{wait:1500}\n/me ����{sex} ��������� � ������{sex} ���������� ������ � ����� �������\n{wait:1500}\n/seeme �������{sex} ��������� � ����{sex} �����\n{wait:1500}\n/try ������� ������{sex2} ����\n{wait:250}\n{help:[������] - ��� ������������ �������� ������� ' ���� ��������� '}\n{help:[�� ������] - ��� ������������ �������� ������� ' �������������� ������ '}"
	},
	[22] = {
		name = "���� ���������",
		text = "{wait:250}\n/me �����{sex} ���� � ������������� ���������\n{wait:1500}\n/me ���� � ���� ������������� ���� � ����, �������{sex} ���\n{wait:1500}\n/me �������{sex} �������� ������� �� ����\n{wait:1100}\n/healwound {pID}"
	},
	[23] = {
		name = "�������������� ������",
		text = "{wait:250}\n/seeme �������{sex} ����� �� ����� � ����{sex} ���������\n{wait:1500}\n/me ������{sex} �������������� ������ � ����� �������\n{wait:1500}\n/me ����{sex} ����� � ������� ������{sex2} ����\n{wait:1500}\n/me �����{sex} ���� � ������������� ���������\n{wait:1500}\n/do ������ ���� � ���� ������������� ���� � ���� � ����������� ���\n{wait:1500}\n/me �������{sex} �� ���� �������� �������\n{wait:1100}\n/healwound {pID}"
	},
	[24] = {
		name = "��������� ���������",
		text = "{wait:250}\n������� ��� ���������� ��������� ���� ���������. \n{wait:1500}\n���������� ������� � ����������� ����.\n{wait:1500}\n/b /showpass {myID}"
	},
	[25] = {
		name = "����� ���. �����",
		text = "{wait:250}\n/todo ������ � ����������� � ����� ��������� * ������ �������\n{wait:1500}\n/me �����{sex} ����� �������� �� ��� {pNick}\n{wait:1100}\n/findmc {pID]"
	},
	[26] = {
		name = "������ ���. �����",
		text = "{wait:250}\n/todo ������ � ������ ���. ����� �� ���� ��� * ������ ������ �����\n{wait:1500}\n/me ����{sex2} ������ ��������\n{wait:1100}\n/givemc {pID}\n{wait:1500}\n/me �������{sex} ���. ����� {pNick}\n{wait:1500}\n/b /showmc id - �������� ���.�����"
	},
	[27] = {
		name = "�������� ���. �����",
		text = "{wait:250}\n/todo ������ � ������� ��� ���.����� * ������ ����� ����������� �����\n{wait:1500}\n/me ����{sex2} ������ ��������\n{wait:1100}\n/updatemc {pID} 0\n{wait:1500}\n/me �������{sex} ���. ����� {pNick}\n{wait:1500}\n/b /showmc id - �������� ���.�����"
	},
	[28] = {
		name = "�� �������",
		text = "{wait:250}\n���� �� ������ �������� � ���. ����� ������ � �������� �� ���. ������..\n{wait:1500}\n��� ��� ��������� �������� �� ������, ��� ����� ������ �������������� ����.\n{wait:1500}\n��������� ����� 5000 ����. ������������ ��������� �����.\n{wait:1500}\n/b /pay {myID} 5000"
	},
	[29] = {
		name = "���� ��� �������",
		text = "{wait:250}\n/me ������{sex} ��������-���� � ����{sex} ������ ����� ��������\n{wait:1500}\n/me ������{sex} ��������-���� �� �������\n{wait:1100}\n/healdisease {pID}"
	},
	[30] = {
		name = "�������: �����",
		text = "{wait:250}\n/do ��������-����: ��������� ������������� | ����� ��� ������\n{wait:1500}\n����������, �� ����� � ��������������� ������.\n{wait:1500}\n/me ����{sex2} ������ � �������� � �������{sex} �������� ��������\n{wait:1100}\n/updatemc {pID} 1"
	},
	[31] = {
		name = "�������: �� �����",
		text = "{wait:250}\n/do ��������-����: ��������� ������������� | �� ����� ��� ������\n{wait:1500}\n� ��� ������������� ���������. ��� ���������� ������ �������.\n{wait:1500}\n/me ����{sex2} ������ � �������� � �������{sex} �������� ��������\n{wait:1100}\n/updatemc {pID} 2"
	},
	[32] = {
		name = "���������",
		text = "{wait:250}\n/todo ������ � ����� ���� ������ � ��������� ����� * ������ �������\n{wait:1500}\n/me ������{sex} ������� ���� ������ ������������ ���������������\n{wait:1500}\n/me ������{sex} ������ �������� � ����������� ��������� �����\n{wait:1500}\n/do ��������� ������ �� ��� {pNick}\n{wait:1500}\n/do � ����� ����� ���������� ��������\n{wait:1500}\n����������� ������ ����� ���������� ����� ��������.\n{wait:1100}\n/healwound {pID}"
	},
	[33] = {
		name = "�� �������",
		text = "{wait:250}\n/seeme ����������{sex} ���������� ����������� � ������\n{wait:1500}\n/me �������{sex} �� ���� �������� �������������� ����\n{wait:1500}\n/me ����{sex} ������� � ��������{sex} ������ �� �����\n{wait:1500}\n/me ������{sex} ������������� ����� � �����{sex} �� ���� ��������\n{wait:1500}\n/do ������� ��������� ��� ��������\n{wait:1500}\n/me ������{sex} ������� � ���������� �����\n{wait:1500}\n/me ����{sex} ����� � ���� �������� � ��������{sex} ������ �������\n{wait:1500}\n/do �������� ������������ ������ �������\n{wait:1100}\n/setsex {pID}"
	},
	[34] = {
		name = "�� �������",
		text = "{wait:250}\n/seeme ���������� ���������� ����������� � ������\n{wait:1500}\n/me �������{sex} �� ���� �������� �������������� ����\n{wait:1500}\n/me ����{sex} ������� � ��������{sex} ������ �� �����\n{wait:1500}\n/me ������{sex} ������������� ����� � �����{sex} �� ���� ��������\n{wait:1500}\n/do ������� ��������� ��� ��������\n{wait:1500}\n/me ��������{sex} � ������{sex} ������� ������� ������\n{wait:1500}\n/me �����������{sex} ������� ������� ������\n{wait:1500}\n/me ����{sex} ����� � ���� �������� � ��������{sex} ������ �������\n{wait:1500}\n/do �������� ������ �������\n{wait:1100}\n/setsex {pID}"
	},
	[35] = {
		name = "�����������",
		text = "{wait:500}\n/todo ������������! � ������ {myNick}! *��������\n{wait:1500}\n/do �� ��������: {myTag} | ������ {myNick} | {myRank}\n{wait:1500}\n��� ��� ���������?"
	},
	[36] = {
		name = "��������� ���������",
		text = "{wait:500}\n�������� �� ����"
	},
	[37] = {
		name = "��������",
		text = "{wait:500}\n����� ������� � �� �������.\n{wait:1500}\n�������� ���� � ����� �������."
	},
	[38] = {
		name = "��������� �������",
		text = "{wait:500}\n/me ��������{sex} �������\n{wait:1500}\n/do �� ��������: {myTag} | ������ {myNick} | {myRank}\n{wait:1500}\n/clist {myClist}"
	},
	[39] = {
		name = "������ ��������",
		text = "{wait:500}\n/do �� ����� ������� ����������� �����\n{wait:1500}\n/me ������{sex} �������� ��������� � �������{sex} ��������\n{wait:1500}\n/me ������{sex} ���������, �� �������\n{wait:1500}\n/heal {myID}"
	}
}																

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
 	while not isSampAvailable() do wait(0) end
	if autoupdate_loaded and enable_autoupdate and Update then
		pcall(Update.check, Update.json_url, Update.prefix, Update.url)
	end
	repeat wait(0) until sampGetCurrentServerName() ~= "SA-MP"
    repeat wait(0) until sampGetCurrentServerName():find("Samp%-Rp.Ru") or sampGetCurrentServerName():find("SRP")
    local server = getSampRpServerName()
    if server == "" then
        thisScript():unload()
    end

	local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	nickname = sampGetPlayerNickname(my_id)
	score = sampGetPlayerScore(my_id)
	NameFormat()
	CheckName()

	sampAddChatMessage('[MedicalHelper] {ffffff}������ ��������.', CL.COLOR_RED)

	print("{ffffff}�������� ������ �������..")
	if not doesDirectoryExist(adress.config) then print("{ffffff}����������� ����� {ff2e2e}'config'. {ffffff}�������� �����.") 
		if createDirectory(adress.config) then print("{ffffff}����� {ff2e2e}'config' {ffffff}������� �������.") end end

	if not doesDirectoryExist(adress.folder) then print("{ffffff}����������� ����� {ff2e2e}MedicalHelper. {ffffff}�������� �����.")
		if createDirectory(adress.folder) then print("{ffffff}����� {ff2e2e}'MedicalHelper' {ffffff}������� �������.") end end

	if not doesFileExist(adress.chatlog) then print("{ffffff}����������� ���� {ff2e2e}chlog. {ffffff}�������� �����.")
		file = io.open(adress.chatlog, "a")
		io.close(file)
	end

	if doesFileExist(adress.config.."/MedicalHelper/roleplay.json") then
		local f = io.open(adress.config.."/MedicalHelper/roleplay.json", 'r')
		if f then
			rptext = decodeJson(f:read('*a'))
		end
		print("{ffffff}������ ����� ��������� {ff2e2e}'roleplay' {ffffff}������ �������.")
	else 
		print("{ffffff}���� ��������� {ff2e2e}'roleplay' {ffffff}�� ������. �������� �����.")
		rptext = buf_rptext
	end
	saveData(rptext, "moonloader/config/MedicalHelper/roleplay.json")
	buf_rp.v = u8(rptext[1].text)
	buf_rp_name.v = u8(rptext[1].name)

	if doesFileExist(adress.config.."/MedicalHelper/note.json") then
		local f = io.open(adress.config.."/MedicalHelper/note.json", 'r')
		if f then
			table_note = decodeJson(f:read('*a'))
		end
		print("{ffffff}������ ����� {ff2e2e}'note' {ffffff}������ �������.")
	else 
		print("{ffffff}���� {ff2e2e}'note' {ffffff}�� ������. �������� �����.")
		table_note = buf_table_note
	end
	saveData(table_note, "moonloader/config/MedicalHelper/note.json")
	buf_note.v = u8(table_note[1].text)
	buf_note_name.v = u8(table_note[1].name)
	
	if doesFileExist(adress.config.."/MedicalHelper/Settings.json") then
		local f = io.open(adress.config.."/MedicalHelper/Settings.json")
		local setf = f:read("*a")
		f:close()
		local res, set = pcall(decodeJson, setf)
		if res and type(set) == "table" then

			buffer.num_tag.v			= set.Tag
			buffer.buf_Clist			= set.Clist
			buffer.buf_nick.v			= u8(set.UserName)
			buffer.buf_ru_nick			= u8(set.UserName)
			buffer.stats_imgui.v		= set.Show_Stats
			buffer.sstats.v				= set.Show_sstats
			buffer.smap.v				= set.Show_smap
			buffer.pluschat.v			= set.Plus_Chat
			buffer.pnumber.v			= set.Plus_Number
			psize.v						= set.Plus_Size
			buffer.namenumber.v			= set.select_name
			buffer.actg.v				= set.Autoclist
			buffer.OffA.v				= set.OffAdds
			buffer.OffG.v				= set.OffGov
			buffer.sstr.v				= set.select_streets
			coords.buf_x_stats			= set.x_stats
			coords.buf_y_stats			= set.y_stats
			coords.buf_x_pluschat		= set.x_pluschat
			coords.buf_y_pluschat		= set.y_pluschat
			coords.buf_x_select			= set.x_select
			coords.buf_y_select			= set.y_select
			buffer.OffAdm.v				= set.OffAdmins
			buffer.buf_OnTag.v			= set.OnTag
			buffer.buf_tag				= u8(set.bTag)
			buffer.OffC.v				= set.OffClue
			buffer.Offcl.v				= set.Offclmenu
	
			if set.tagl then
				for i,v in ipairs(set.tagl) do
					chgName.tag[tonumber(i)] = u8(v)
				end
			end

			if set.statsl then
				for i, v in ipairs(set.statsl) do
					chgName.stats[tonumber(i)] = u8(v)
				end
			end

			if set.clistl then
				for i, v in ipairs(set.clistl) do
					chgName.clist[tonumber(i)] = u8(v)
				end
			end

			print("{ffffff}������ ����� {ff2e2e}'Settings' {ffffff}������ �������.")
		else
			print("{ffffff}���� �������� {ff2e2e}'Settings' {ffffff}���������. �������� �����.")
			os.remove(adress.config.."/MedicalHelper/Settings.json")
			needsave()
		end
	else
		print("{ffffff}���� �������� {ff2e2e}'Settings' {ffffff}�� ������. �������� �����.")
		needsave()
	end

	if inicfg.save(col, adress.col) then print("{ffffff}������ ����� {ff2e2e}'Color' {ffffff}������ �������.") end
		
	-- font = renderCreateFont(ini.Settings.FontName, ini.Settings.FontSize, ini.Settings.FontFlag)

	thread = lua_thread.create(function() return end) 
	lua_thread.create(function()
		antiflood_get_text = os.clock() * 1000
		chatinput_text = ""
		while true do
			wait(0)
			local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
			nickname = sampGetPlayerNickname(id)
			score = sampGetPlayerScore(id)
			ping = sampGetPlayerPing(id)
			count = sampGetPlayerCount(false)
			local color = sampGetPlayerColor(id)
			color = string.format("%X", tonumber(color))
			if #color == 8 then _, color = string.match(color, "(..)(......)") end
			if os.clock() * 1000 - antiflood_get_text > 300 then
				antiflood_get_text = os.clock() * 1000
				chatinput_text = sampGetChatInputText()
			end
		end
	end)

	if doesFileExist(adress.config.."/MedicalHelper/cmdSetting.json") then
	--register cmd
		local f = io.open(adress.config.."/MedicalHelper/cmdSetting.json")
		local res, keys = pcall(decodeJson, f:read("*a"))
		f:flush()
		f:close()
		if res and type(keys) == "table" then
			for i, v in ipairs(keys) do
				if #v.key > 0 then
					
					rkeys.registerHotKey(v.key, true, onHotKeyCMD)
					cmdBind[i].key = v.key
					table.insert(keysList, v.key)
				end
			end
			print("{ffffff}������ ����� {ff2e2e}'cmdSettings' {ffffff}������ �������.")
		else
			print("{ffffff}���� {ff2e2e}'cmdSetting' ���������. {ffffff}�������� �����.")
			os.remove(adress.config.."/MedicalHelper/cmdSetting.json")
		end
	else
		print("{ffffff}���� {ff2e2e}'cmdSetting' �� ������. {ffffff}�������� �����.")
		os.remove(adress.config.."/MedicalHelper/cmdSetting.json")
	end

		lockPlayerControl(false)

		sampRegisterChatCommand('vehs', cmd_vehs)
		sampRegisterChatCommand('clmenu', clickmenu_imgui)
		sampRegisterChatCommand('mh', function()
			buffer.nh_menu.v = not buffer.nh_menu.v
		end)
		--[[sampRegisterChatCommand('cord', function()
			local X, Y, Z = getCharCoordinates(PLAYER_PED)
			sampAddChatMessage('X: '..X..', Y: '..Y..', Z: '..Z, -1)
		end)
		sampRegisterChatCommand('test', function()
			sampAddChatMessage('--------------------------------------------------------', -1)
			sampAddChatMessage('������� �� ����� San Andreas:', -1)
			sampAddChatMessage('1. ����� �����������: {ff2e2e}5000 {ffffff}����', -1)
			sampAddChatMessage('2. ���� �� �������: {ff2e2e} 999 {ffffff}����', -1)
			sampAddChatMessage('3. ��������: {ff2e2e} 35000 {ffffff}����', -1)
			sampAddChatMessage('4. ������ �����: {ff2e2e} 123456789 {ffffff}����', -1)
			sampAddChatMessage('5. ������� �����: {ff2e2e} 18:00', -1)
			sampAddChatMessage('--------------------------------------------------------', -1)
		end) ]]

		sampAddChatMessage(string.format("[MedicalHelper]{FFFFFF} �����������,{ff2e2e} %s.{FFFFFF} ��� ��������� �������� ���� ����������� {ff2e2e}/mh.", sampGetPlayerNickname(my_id):gsub("_"," ")), CL.COLOR_RED)
		variable.myadds = 0
	while true do
		imgui.ShowCursor = buffer.nh_menu.v or buffer.clmenu.v
		imgui.Process = buffer.stats_imgui.v or buffer.nh_menu.v or buffer.pluschat.v or buffer.clmenu.v
		wait(0)
		--	takehandle()
			timer()
			if buffer.actg.v then
				autoclist()                                                                                                                                                                                                                  
			end
			if #t1 > 30 then table.remove(t1, 1) end
			fchat_check.v = col.Colors.active_fchat
			sms_check.v = col.Colors.active_sms
			sqchat_check.v = col.Colors.active_sqchat
			dep_check.v = col.Colors.active_dep
			ms = math.ceil(os.clock() * 1000 - variable.antiflood)

			if not sampIsDialogActive() and ms > 1800 and variable.pstats == 1 then
				variable.pstats = 2
				sampSendChat("/stats")
			end

			if not sampIsDialogActive() and ms > 1800 and variable.check_zp == 1 then
				wait(1000)
				variable.check_zp = 2
				sampSendChat("/paycheck")
			end

	end
end

function getSampRpServerName()
    local result = ""
    local server = sampGetCurrentServerName():gsub("|", "")
    local server_find = { "Underground", "Under", "UG", "Revo", "Legacy", "Revolution"}
    for i = 1, #server_find do
        if server:find(server_find[i]) then
            result = server_find[i]
        end
    end
    return result
end

function join_argb(a, b, g, r)
    local argb = b
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function imgui.OnDrawFrame()
	_, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)

	if buffer.pluschat.v then
		imgui.PushStyleVar(imgui.StyleVar.WindowRounding, sRound.v)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(imgui.ImColor(argbW):GetFloat4()))
		imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(imgui.ImColor(1, 1, 1, 0):GetFloat4()))
		imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(imgui.ImColor(argbT):GetFloat4()))
		imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(0.5, 0.5, 0.5, 0.25))
		imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.43, 0.43, 0.50, 0.0))
			imgui.SetNextWindowPos(imgui.ImVec2(coords.buf_x_pluschat, coords.buf_y_pluschat), imgui.Cond.Always)
			imgui.Begin('##pluschatgui', buffer.pluschat, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.AlwaysAutoResize) --
				imgui.CenterText(fa.ICON_COMMENTING.. u8' �������������� ���:')
				imgui.Separator()
				imgui.BeginChild('##pluschat_1', imgui.ImVec2(psizeX, psize.v))
					imgui.TextColoredRGB(table.concat(t1, '\n'))
					imgui.SetScrollHere()
				imgui.EndChild()
			imgui.End()
		imgui.PopStyleColor(5)
		imgui.PopStyleVar()
	end

	if buffer.clmenu.v then
		imgui_clmenu()
	end

	if buffer.stats_imgui.v then
		imgui.PushStyleVar(imgui.StyleVar.WindowRounding, sRound.v)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(imgui.ImColor(argbW):GetFloat4()))
		imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(imgui.ImColor(argbT):GetFloat4()))
		imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(0.5, 0.5, 0.5, 0.25))
			imgui.SetNextWindowPos(imgui.ImVec2(coords.buf_x_stats, coords.buf_y_stats), imgui.Cond.Always)
			imgui.Begin('##statsgui', buffer.stats_imgui, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse  + imgui.WindowFlags.AlwaysAutoResize)
				if buffer.sstats.v == true then
					imgui.CenterText(fa.ICON_USER.. u8' ��������:')
					imgui.Separator()
					imgui.Spacing()
					imgui.Text(fa.ICON_USER_CIRCLE .. u8' ���: ' ..nickname.. ' [' ..my_id.. ']')
					imgui.Text(fa.ICON_LINE_CHART .. u8' �������: ' ..score.. ' [' ..u8(u8:decode(chgName.stats[1])).. ']')
					imgui.Text(fa.ICON_BRIEFCASE .. u8' �����������: '..u8(u8:decode(chgName.stats[3])))
					imgui.Text(fa.ICON_GRADUATION_CAP.. u8' ����: ' ..u8(u8:decode(chgName.stats[4])))
					imgui.Text(' '..fa.ICON_USD.. u8'  ��������: ' ..variable.value_zp.. u8' ����')
					imgui.Text(fa.ICON_CLOCK_O.. u8' �����:'.. os.date(" %X %d.%m.%Y", os.time()))
					imgui.Spacing() imgui.Spacing()
				end
				if buffer.smap.v == true then
					imgui.CenterText(fa.ICON_MAP_MARKER.. u8' ��������������:')
					imgui.Separator()
					imgui.Text(fa.ICON_CARET_RIGHT.. u8' '.. u8(calculateCity(1))..' ['..u8(calculateSquare())..']')
					imgui.Text(fa.ICON_CARET_RIGHT.. u8' ' ..u8(calculateZone(x,y,z)))
					imgui.Spacing() imgui.Spacing()
				end				
			imgui.End()
		imgui.PopStyleColor(3)
		imgui.PopStyleVar()
	end

	if buffer.nh_menu.v then
		w, h = getScreenResolution()
		imgui.SetNextWindowSize(imgui.ImVec2(800, 504), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin('##begin_nh', 0, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
			imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.45, 0.45, 0.45, 1.00))
				imgui.CenterText(fa.ICON_HEARTBEAT.. ' Medical Helper')
			imgui.PopStyleColor()
			imgui.BeginChild('##main_m', imgui.ImVec2(782, 440), true)
				imgui.TextColored(imgui.ImVec4(0.90, 0.90, 0.90, 1.00), fa.ICON_USER_CIRCLE.. '  ' ..nickname.. '   ID: '.. my_id.. '   '.. fa.ICON_LEVEL_UP.. ' '.. score)
				imgui.SameLine()
				imgui.CenterText(os.date("%X  %d.%m.%y", os.time()))
				imgui.SameLine(630)
				imgui.TextColored(imgui.ImVec4(0.90, 0.90, 0.90, 1.00), fa.ICON_RSS.. ' ' ..ping.. '   ' ..fa.ICON_USERS.. ' ' ..count.. '   ' ..fa.ICON_CLOUD_DOWNLOAD.. '  ' ..sver)
				imgui.Separator()
				imgui.Spacing()
				imgui.SameLine(-1)
				imgui.BeginGroup()
					imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 1.0)
					imgui.PushFont(fsStil)
						if ButtonMenu(fa.ICON_USER, but.select_menu[1]) then but.select_menu = {true,false, false, false, false} end
						if ButtonMenu(fa.ICON_INFO_CIRCLE, but.select_menu[2]) then but.select_menu = {false, true, false, false, false} end
						if ButtonMenu(fa.ICON_COGS, but.select_menu[3]) then but.select_menu = {false, false, true, false, false} end
						if ButtonMenu(fa.ICON_COMMENTING, but.select_menu[4]) then but.select_menu = {false, false, false, true, false} end
						if ButtonMenu(fa.ICON_FILE_TEXT, but.select_menu[5]) then but.select_menu = {false, false, false, false, true} end
					imgui.PopFont()
					imgui.PopStyleVar()
				imgui.EndGroup()
				imgui.SameLine(46)
				imgui.BeginChild('##set', imgui.ImVec2(732, 406), true)
					
					if but.select_menu[1] then
						imgui.PushStyleVar(imgui.StyleVar.ChildWindowRounding, 6.0)
						imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(1.00, 0.21, 0.21, 1.00))
							imgui.BeginChild('##fonstats', imgui.ImVec2(332, 300), true)
								imgui.CenterText(u8'���������� ���������')
								imgui.SameLine()
								imgui.SetCursorPos(imgui.ImVec2(304, 4))
								imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 31)
									if imgui.Button(fa.ICON_REFRESH, imgui.ImVec2(21, 21)) then variable.pstats = 1 end
								imgui.PopStyleVar()
							imgui.EndChild()
							imgui.SameLine()
							imgui.BeginChild('##fonadds', imgui.ImVec2(200, 134), true)
								imgui.CenterText(u8'���. ����������')
							imgui.EndChild()
						imgui.PopStyleColor()
						imgui.PopStyleVar()
						imgui.SetCursorPos(imgui.ImVec2(14, 36))
							menu_stats()
						imgui.SameLine(351)
						imgui.BeginChild('##nhadds', imgui.ImVec2(188, 100), true)
							imgui.Text(u8'�������� �����: '..medWork.heal_all)
							imgui.Text(u8'������ ���.���� �����: '..medWork.medcard_all)
							imgui.Text(u8'�������� �� �����: '..medWork.heal_post)
							imgui.Text(u8'������ ���.���� �� �����: '..medWork.medcard_post)
						imgui.EndChild()
					end	
					if but.select_menu[2] then
						imgui.CenterText(u8'����������')
						imgui.Spacing()
						imgui.Separator()
						imgui.Spacing()
						imgui.Text(u8'		�������:')
						imgui.Text(u8'  /mh - ��������� �������� ����;')
						imgui.Text(u8'  /vehs - ����� ���������� �� �������� / ID;')
						imgui.Text(u8'  /clmenu - ������� ��� ������ ������������� ����;')
						imgui.NewLine()
						imgui.Text(u8'		������� ����������:')
						imgui.Text(u8'  2.0.4 by Galileo_Galilei & Serhiy_Rubin')
						imgui.Text(u8'  3.0.0 by Twix Imperies')
						imgui.Text(u8'  4.0.0 by zmarchev')
						imgui.Text(u8'  - ����������� ������� ��� ������� �� imgui;')
						imgui.Text(u8'  - ��������� �������������� ���� � �����������;')
						imgui.Text(u8'  - ��������� ������������ ���� ������� ������ � ���������;')
						imgui.Text(u8'  - ��������� �������������� ��������� � �������;')
						imgui.NewLine()
						imgui.Text(u8'  ��������� ������� blast.hk � ��� �������������, Rubin Mods, Mia_Twix & David_Guetta,')
						imgui.Text(u8'  � ��� �� ������� Ministry of Health ������� Revolution �� ������ � ���������� �������.')
					end
					if but.select_menu[3] then
						imgui.SetCursorPos(imgui.ImVec2(0, 0))
						imgui.BeginGroup()
							imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 1.0)
								if ButtonSettings(u8"��������", but.select_settings[1]) then but.select_settings = {true,false, false, false} end
									imgui.SameLine(132)
								if ButtonSettings(u8"���. ����", but.select_settings[2]) then but.select_settings = {false, true,false, false} end
									imgui.SameLine(128+130+6)
								if ButtonSettings(u8"���", but.select_settings[3]) then but.select_settings = {false, false, true, false} end
									imgui.SameLine(128+130+130+8)
								if ButtonSettings(u8"���������", but.select_settings[4]) then but.select_settings = {false, false,  false, true} end
							imgui.PopStyleVar()
								imgui.SetCursorPos(imgui.ImVec2(0, 30))
								imgui.Separator()
						imgui.EndGroup()

						if but.select_settings[1] then
							imgui.SameLine(10)
							imgui.Spacing() imgui.Spacing()
							imgui.BeginGroup()
								imgui.Spacing()
								combo_name()
								imgui.SameLine()
								imgui.Text(u8'������� ������� ����������� ������ ����� � ����.')
								imgui.PushItemWidth(200)
									if imgui.InputText(u8"���������������� ��� ", buffer.buf_nick, imgui.InputTextFlags.CallbackCharFilter, filter(1, "[�-�%s]+")) then
										needsave()
										buffer.buf_ru_nick = u8:decode(u8(buffer.buf_nick.v))
										CheckName()
									end
								imgui.PopItemWidth()
								imgui.SameLine()
								ask()						
								imgui.Hint(u8'�� ������ �������� ��� � �������, ����������� � ����;\n����������� ������� ���� ��� ������� �������������;\n�������� ������ ������, ��� ������������� ������������ ����.', 0.3)
								imgui.Spacing()
								imgui.Text(u8'�������������� ��������� ����� ����:')
								imgui.SameLine(300)
								if imgui.ToggleButton("autoclisttoggle", buffer.actg) then
									needsave()
								end
								imgui.SameLine()
								if buffer.actg.v then
									imgui.Text(u8'��������')
								else
									imgui.TextDisabled(u8'���������')
								end

								imgui.Text(u8'�������������� ���� ����:')
								imgui.SameLine(300)
								if imgui.ToggleButton("ontagontag", buffer.buf_OnTag) then
									buffer.buf_tag = tostring(chgName.tag[buffer.num_tag.v+1])
									needsave()
								end
								imgui.SameLine()
								if buffer.buf_OnTag.v then
									imgui.Text(u8'��������')
								else
									imgui.TextDisabled(u8'���������')
								end

								imgui.Text(u8'������� �������������� �� ������� ����:')
								imgui.SameLine(300)
								if imgui.ToggleButton("selstrtoggle", buffer.sstr) then
									needsave()
								end
								imgui.SameLine()
								if buffer.sstr.v then
									imgui.Text(u8'��������')
								else
									imgui.TextDisabled(u8'���������')
								end

								imgui.Text(u8'��������� ���� ������� ���������:')
								imgui.SameLine(300)
								if imgui.ToggleButton("clmenupkm", buffer.Offcl) then
									needsave()
								end
								imgui.SameLine()
								if buffer.Offcl.v then
									imgui.Text(u8'��������')
								else
									buffer.clmenu.v = false
									buffer.clmenu_nicks.v = false
									imgui.TextDisabled(u8'���������')
								end

								imgui.Text(u8'��������� ��������� ���� ������� ���������:')
								imgui.SameLine(300)
								if imgui.Button(u8'��������', imgui.ImVec2(100, 20)) then
									lua_thread.create(function ()
										checkCursor = true
										but.select_button[10] = true
										buffer.nh_menu.v = false
										buffer.clmenu.v = true
										sampSetCursorMode(3)
										sampAddChatMessage('[MedicalHelper] {FFFFFF}������� {FF2E2E}������ {FFFFFF}��� ���������� �������', CL.COLOR_RED)
										while checkCursor do
											local sX, sY = getCursorPos()
											posXs, posYs = sX, sY
											coords.buf_x_select = posXs; coords.buf_y_select = posYs
											if isKeyDown(32) then
												sampSetCursorMode(0)
												checkCursor = false
												buffer.nh_menu.v = true
												but.select_button[10] = false
												buffer.clmenu.v = false
												if needsave() then sampAddChatMessage('[MedicalHelper] {FFFFFF}������� ���������!', CL.COLOR_RED) end
											end
											wait(0)
										end
									end)
								end


							imgui.EndGroup()
						end

						if but.select_settings[2] then
							
							imgui.Spacing()
							imgui.BeginChild('####2s1', imgui.ImVec2(300, 150), true)						
								imgui.CenterText(fa.ICON_TH_LARGE.. u8' ������� ��� �������������� ����:')
								imgui.Separator()
								imgui.Spacing() imgui.Spacing()
								imgui.PushItemWidth(284)
		        					if imgui.SliderFloat('##Round', sRound, 0.0, 10.0, u8"���������� �����: %.1f") then
										col.Style.round = sRound.v
										main_style()
										inicfg.save(col, adress.col)
									end
								imgui.PopItemWidth()
								imgui.Spacing()
								if imgui.ColorEdit4(u8'�������� ���� ����', colorW, imgui.ColorEditFlags.NoInputs) then
									argbW = imgui.ImColor.FromFloat4(colorW.v[1], colorW.v[2], colorW.v[3], colorW.v[4]):GetU32()
									col.Style.colorW = argbW
									inicfg.save(col, adress.col)
			        			end
			        			if imgui.ColorEdit4(u8'�������� ���� ������', colorT, imgui.ColorEditFlags.NoInputs) then
			            			argbT = imgui.ImColor.FromFloat4(colorT.v[1], colorT.v[2], colorT.v[3], colorT.v[4]):GetU32()
			            			col.Style.colorT = argbT
									inicfg.save(col, adress.col)
			        			end
							imgui.EndChild()
							imgui.SameLine()
							imgui.BeginChild('####2s2', imgui.ImVec2(300, 150), true)	
								imgui.CenterText(fa.ICON_ADDRESS_CARD.. u8' ���������� � ���������:')
								imgui.Separator()
								imgui.Spacing() imgui.Spacing()
								
								imgui.Text(u8'���������� ����������:')
								imgui.SameLine(186)
								if imgui.ToggleButton('##Stats', buffer.sstats) then
									if buffer.sstats.v == true then
										buffer.stats_imgui.v = true
									else
										if buffer.smap.v == false then
											buffer.stats_imgui.v = false
										end
									end
									needsave()
								end
								imgui.SameLine()
								if buffer.sstats.v then
									imgui.Text(u8'��������')
								else
									imgui.TextDisabled(u8'���������')
								end

								imgui.Text(u8'���������� ��������������:')
								imgui.SameLine(186)
								if imgui.ToggleButton("strtoggle", buffer.smap) then
									if buffer.smap.v == true then
										buffer.stats_imgui.v = true
									else
										if buffer.sstats.v == false then
											buffer.stats_imgui.v = false
										end
									end
									needsave()
								end
								imgui.SameLine()
								if buffer.smap.v then
									imgui.Text(u8'��������')
								else
									imgui.TextDisabled(u8'���������')
								end
								imgui.Spacing()

								if imgui.Button(u8'��������� ����������', imgui.ImVec2(286, 20)) then
									
								lua_thread.create(function ()
										checkCursor = true
										buffer.nh_menu.v = false
										sampSetCursorMode(3)
										sampAddChatMessage('[MedicalHelper] {FFFFFF}������� {FF2E2E}������ {FFFFFF}��� ���������� �������', CL.COLOR_RED)
										while checkCursor do
											local cX, cY = getCursorPos()
											posX, posY = cX, cY
											coords.buf_x_stats = posX; coords.buf_y_stats = posY
											if isKeyDown(32) then
												sampSetCursorMode(0)
												checkCursor = false
												buffer.nh_menu.v = true
												if needsave() then sampAddChatMessage('[MedicalHelper] {FFFFFF}������� ���������!', CL.COLOR_RED) end
											end
											wait(0)
										end
									end)
								end
							imgui.EndChild()
							imgui.BeginChild('####2s3', imgui.ImVec2(606, 200), true)

								imgui.CenterText(fa.ICON_COMMENTING.. u8' �������������� ���:')
								imgui.Separator()
								imgui.Spacing() imgui.Spacing()
							imgui.BeginGroup()
								imgui.Text(u8'���������� ���. ���:')
								imgui.SameLine(186)
								if imgui.ToggleButton(u8('##plus'), buffer.pluschat) then
									if buffer.pluschat.v == false then
									--	buf_Plus_Adds.v = false
									--	buf_Plus_Radio.v = false
									end
								--	needsave()
								end
								imgui.SameLine()
								if buffer.pluschat.v then
									imgui.Text(u8'��������')
								else
									imgui.TextDisabled(u8'���������')
								end

								if imgui.Button(u8'��������� ���. ����', imgui.ImVec2(286, 20)) then
									lua_thread.create(function ()
										checkCursorp = true
										buffer.nh_menu.v = false
										sampSetCursorMode(3)
										sampAddChatMessage('[MedicalHelper] {FFFFFF}������� {FF2E2E}������ {FFFFFF}��� ���������� �������', CL.COLOR_RED)
										while checkCursorp do
											local cXp, cYp = getCursorPos()
											posXp, posYp = cXp, cYp
											coords.buf_x_pluschat = posXp; coords.buf_y_pluschat = posYp
											if isKeyDown(32) then
												sampSetCursorMode(0)
												checkCursorp = false
												buffer.nh_menu.v = true
												if needsave() then sampAddChatMessage('[MedicalHelper] {FFFFFF}������� ���������!', CL.COLOR_RED) end
											end
											wait(0)
										end
									end)
								end
							
								imgui.Spacing()

								imgui.PushItemWidth(80)
									imgui.InputInt(u8"���������� ������������ �����", buffer.pnumber)
								imgui.PopItemWidth()
								if buffer.pnumber.v >= 4 or buffer.pnumber.v <=12 then
									if buffer.pnumber.v <= 4 then buffer.pnumber.v = 4; psize.v = 70
									elseif buffer.pnumber.v == 5 then psize.v = 90
									elseif buffer.pnumber.v == 6 then psize.v = 110
									elseif buffer.pnumber.v == 7 then psize.v = 130
									elseif buffer.pnumber.v == 8 then psize.v = 145
									elseif buffer.pnumber.v == 9 then psize.v = 165
									elseif buffer.pnumber.v == 10 then psize.v = 182
									elseif buffer.pnumber.v == 11 then psize.v = 200
									elseif buffer.pnumber.v >= 12 then buffer.pnumber.v = 12; psize.v = 220
									end
								--	needsave()
								end

								if imgui.Button(u8'��������� ���������', imgui.ImVec2(286, 20)) then
									lua_thread.create( function()
										psizeX, psizeY = 970, psize.v
									end)
								end
							imgui.EndGroup()
								imgui.SameLine(350)
							imgui.BeginGroup()
							--	if imgui.RadioButton(u8'���������� ����������', buf_Plus_Adds) then  buf_Plus_Adds.v = not buf_Plus_Adds.v; buf_Plus_Adds.v = buf_Plus_Adds.v needsave() end
							--	if imgui.RadioButton(u8'���������� �����', buf_Plus_Radio) then buf_Plus_Radio.v = not buf_Plus_Radio.v; buf_Plus_Radio.v = buf_Plus_Radio.v needsave() end
							imgui.EndGroup()
							imgui.EndChild()

						end -- ����� �������� � ����������� ���. ����

						if but.select_settings[3] then -- ��������� ����
							imgui.SameLine(10)
							imgui.Spacing() imgui.Spacing()
							imgui.BeginGroup()
								imgui.BeginGroup()
									imgui.Spacing()
									imgui.Text(u8' �������� ���� ���� �������: [/r] & [/rb]')
									if imgui.ColorEdit3("##1", fchat, imgui.ColorEditFlags.NoInputs) then
										local clr = join_argb(0, fchat.v[3] * 255, fchat.v[2] * 255, fchat.v[1] * 255)
										local r,g,b = fchat.v[3] * 255, fchat.v[2] * 255, fchat.v[1] * 255
										col.Colors.col_fchat = ("0xFF%06X"):format(clr)
										col.Colors.fchat1 = r		col.Colors.fchat2 = g		col.Colors.fchat3 = b
										inicfg.save(col, adress.col)
									end
									imgui.SameLine()
									imgui.Text(u8'������� ����')
									imgui.SameLine(130)
									if imgui.ToggleButton('##color1', fchat_check) then
										col.Colors.active_fchat = fchat_check.v
										inicfg.save(col, adress.col)
									end
									imgui.SameLine()
									if fchat_check.v then
										imgui.Text(u8'��������')
									else
										imgui.TextDisabled(u8'���������')
									end
									imgui.Spacing()

									imgui.Text(u8' �������� ���� ���� ���������: [/t] & [/sms]')
									if imgui.ColorEdit3("##2", sms, imgui.ColorEditFlags.NoInputs) then
										local clr = join_argb(0, sms.v[3] * 255, sms.v[2] * 255, sms.v[1] * 255)
										local r,g,b = sms.v[3] * 255, sms.v[2] * 255, sms.v[1] * 255
										col.Colors.col_sms = ("0xFF%06X"):format(clr)
										col.Colors.sms1 = r		col.Colors.sms2 = g		col.Colors.sms3 = b
										inicfg.save(col, adress.col)
									end
									imgui.SameLine()
									imgui.Text(u8'������� ����')
									imgui.SameLine(130)
									if imgui.ToggleButton('##color2', sms_check) then
										col.Colors.active_sms = sms_check.v
										inicfg.save(col, adress.col)
									end
									imgui.SameLine()
									if sms_check.v then
										imgui.Text(u8'��������')
									else
										imgui.TextDisabled(u8'���������')
									end
									imgui.Spacing()

									imgui.Text(u8' �������� ���� ���� ������: [/fs] & [/u]')
									if imgui.ColorEdit3("##3", sqchat, imgui.ColorEditFlags.NoInputs) then
										local clr = join_argb(0, sqchat.v[3] * 255, sqchat.v[2] * 255, sqchat.v[1] * 255)
										local r,g,b = sqchat.v[3] * 255, sqchat.v[2] * 255, sqchat.v[1] * 255
										col.Colors.col_sqchat = ("0xFF%06X"):format(clr)
										col.Colors.sqchat1 = r		col.Colors.sqchat2 = g		col.Colors.sqchat3 = b
										inicfg.save(col, adress.col)
									end
									imgui.SameLine()
									imgui.Text(u8'������� ����')
									imgui.SameLine(130)
									if imgui.ToggleButton('##color3', sqchat_check) then
										col.Colors.active_sqchat = sqchat_check.v
										inicfg.save(col, adress.col)
									end
									imgui.SameLine()
									if sqchat_check.v then
										imgui.Text(u8'��������')
									else
										imgui.TextDisabled(u8'���������')
									end

									imgui.Text(u8' �������� ���� ����� ������������: [/dep]')
									if imgui.ColorEdit3("##4", dep, imgui.ColorEditFlags.NoInputs) then
										local clr = join_argb(0, dep.v[3] * 255, dep.v[2] * 255, dep.v[1] * 255)
										local r,g,b = dep.v[3] * 255, dep.v[2] * 255, dep.v[1] * 255
										col.Colors.col_dep = ("0xFF%06X"):format(clr)
										col.Colors.dep1 = r		col.Colors.dep2 = g		col.Colors.dep3 = b
										inicfg.save(col, adress.col)
									end
									imgui.SameLine()
									imgui.Text(u8'������� ����')
									imgui.SameLine(130)
									if imgui.ToggleButton('##color4', dep_check) then
										col.Colors.active_dep = dep_check.v
										inicfg.save(col, adress.col)
									end
									imgui.SameLine()
									if dep_check.v then
										imgui.Text(u8'��������')
									else
										imgui.TextDisabled(u8'���������')
									end
								imgui.EndGroup()
									imgui.SameLine(340)
								imgui.BeginGroup()
									imgui.Text(u8'������ ����������:')
									imgui.SameLine(160)
									if imgui.ToggleButton("addstoggle", buffer.OffA) then
										variable.myadds = 0
										needsave()
									end
									imgui.SameLine()
									if buffer.OffA.v then
										imgui.Text(u8'��������')
									else
										imgui.TextDisabled(u8'���������')
									end

									imgui.Text(u8'������ ���. �������:')
									imgui.SameLine(160)
									if imgui.ToggleButton("govtoggle", buffer.OffG) then
										needsave()
									end
									imgui.SameLine()
									if buffer.OffG.v then
										imgui.Text(u8'��������')
									else
										imgui.TextDisabled(u8'���������')
									end

									imgui.Text(u8'������ ���. ���������:')
									imgui.SameLine(160)
									if imgui.ToggleButton("adminadmin", buffer.OffAdm) then
										needsave()
									end
									imgui.SameLine()
									if buffer.OffAdm.v then
										imgui.Text(u8'��������')
									else
										imgui.TextDisabled(u8'���������')
									end

									imgui.Text(u8'������ ��������� �������:')
									imgui.SameLine(160)
									if imgui.ToggleButton("clu", buffer.OffC) then
										needsave()
									end
									imgui.SameLine()
									if buffer.OffC.v then
										imgui.Text(u8'��������')
									else
										imgui.TextDisabled(u8'���������')
									end
								imgui.EndGroup()
							imgui.EndGroup()
						end -- ����� �������� ����

						if but.select_settings[4] then

						--/////Command				
							imgui.BeginGroup()
								imgui.Spacing()
								imgui.CenterText(u8"������ ������, � ������� �� ������ ��������� ������� ���������.")
								imgui.Dummy(imgui.ImVec2(0, 2))
								imgui.BeginChild("cmd list", imgui.ImVec2(0, 285), true)
									imgui.Columns(3, "keybinds", true); 
									imgui.SetColumnWidth(-1, 80); 
									imgui.Text(u8"�������"); 
									imgui.NextColumn();
									imgui.SetColumnWidth(-1, 450); 
									imgui.Text(u8"��������"); 
									imgui.NextColumn(); 
									imgui.Text(u8"�������"); 
									imgui.NextColumn(); 
									imgui.Separator();
									for i,v in ipairs(cmdBind) do
										if tonumber(chgName.stats[5]+1) >= v.rank then
											if imgui.Selectable(u8(v.cmd), variable.selected_cmd == i, imgui.SelectableFlags.SpanAllColumns) then variable.selected_cmd = i end
											imgui.NextColumn(); 
											imgui.Text(u8(v.desc)); 
											imgui.NextColumn();
											if #v.key == 0 then imgui.Text(u8"���") else imgui.Text(table.concat(rkeys.getKeysName(v.key), " + ")) end	
											imgui.NextColumn()
										else
											imgui.PushStyleColor(imgui.Col.Text, imgui.ImColor(84, 84, 84, 255):GetVec4())
												if imgui.Selectable(u8(v.cmd), variable.selected_cmd == i, imgui.SelectableFlags.SpanAllColumns) then variable.selected_cmd = i end
												imgui.NextColumn(); 
												imgui.Text(u8(v.desc)); 
												imgui.NextColumn(); 
												if #v.key == 0 then imgui.Text(u8"���") else imgui.Text(table.concat(rkeys.getKeysName(v.key), " + ")) end	
												imgui.NextColumn()
											imgui.PopStyleColor(1)
										end
									end
								imgui.EndChild();
								if cmdBind[variable.selected_cmd].rank <= tonumber(chgName.stats[5]+1) then
									imgui.Text(u8"�������� ������� �������������� ������� ���������.")
									imgui.Dummy(imgui.ImVec2())
									if imgui.Button(u8"��������� �������", imgui.ImVec2(140, 20)) then 
										imgui.OpenPopup(u8"��������� ������� ���������")
										lockPlayerControl(true)
										editKey = true
									end
									imgui.SameLine();
									if imgui.Button(u8"������� �������", imgui.ImVec2(140, 20)) then 
										rkeys.unRegisterHotKey(cmdBind[variable.selected_cmd].key)
										unRegisterHotKey(cmdBind[variable.selected_cmd].key)
										cmdBind[variable.selected_cmd].key = {}

										local f = io.open(adress.config.."/MedicalHelper/cmdSetting.json", "w")
										f:write(encodeJson(cmdBind))
										f:flush()
										f:close()
									end
									imgui.SameLine();
								else
									imgui.Text(u8"������ ������� �������� � " .. cmdBind[variable.selected_cmd].rank .. u8" �����")
								end
					
							imgui.EndGroup()

							imgui.PushStyleColor(imgui.Col.PopupBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.94))
							if imgui.BeginPopupModal(u8"��������� ������� ���������", null, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoMove) then
					
								imgui.CenterText(u8"������� �� ������� ��� ��������� ������ ��� ��������� ���������.")
								imgui.Separator()
								imgui.Spacing()
								imgui.Text(u8"�����������:")
								imgui.Bullet()	imgui.TextDisabled(u8"������� ��� ��������� - Alt, Ctrl, Shift")
								imgui.Bullet()	imgui.TextDisabled(u8"���������� �����")
								imgui.Bullet()	imgui.TextDisabled(u8"�������������� ������� F1-F12")
								imgui.Bullet()	imgui.TextDisabled(u8"����� ������� ������")
								imgui.Bullet()	imgui.TextDisabled(u8"������� ������ Numpad")
								imgui.Spacing()
								imgui.Checkbox(u8"������������ ��� � ���������� � ���������", cb_RBUT)
								imgui.Checkbox(u8"������������ Button 1 (��� ������� ����)", cb_x1)
								imgui.Checkbox(u8"������������ Button 2 (��� ������� ����)", cb_x2)
								imgui.Spacing()
								imgui.Text(u8"������� �������(�): ");
								imgui.SameLine();
					
								if imgui.IsMouseClicked(0) then
									lua_thread.create(function()
										wait(500)	
										setVirtualKeyDown(3, true)
										wait(0)
										setVirtualKeyDown(3, false)
									end)
								end	
				
								if #(rkeys.getCurrentHotKey()) ~= 0 and not rkeys.isBlockedHotKey(rkeys.getCurrentHotKey()) then				
									if not rkeys.isKeyModified((rkeys.getCurrentHotKey())[#(rkeys.getCurrentHotKey())]) then
										currentKey[1] = table.concat(rkeys.getKeysName(rkeys.getCurrentHotKey()), " + ")
										currentKey[2] = rkeys.getCurrentHotKey()
									end
								end

								imgui.TextColored(imgui.ImColor(255, 54, 54, 255):GetVec4(), currentKey[1])
								if isHotKeyDefined then
									imgui.TextColored(imgui.ImColor(255, 54, 54, 255):GetVec4(), u8"������ ���� ��� ����������!")
								end
								imgui.Spacing() imgui.Spacing()
								imgui.BeginGroup()
									if imgui.Button(u8"����������", imgui.ImVec2(126, 0)) then
										if but.select_settings[4] then
											if cb_RBUT.v then table.insert(currentKey[2], 1, vkeys.VK_RBUTTON) end
											if cb_x1.v then table.insert(currentKey[2], vkeys.VK_XBUTTON1) end
											if cb_x2.v then table.insert(currentKey[2], vkeys.VK_XBUTTON2) end
											if rkeys.isHotKeyExist(currentKey[2]) then 
												isHotKeyDefined = true
											else
												rkeys.unRegisterHotKey(cmdBind[variable.selected_cmd].key)
												unRegisterHotKey(cmdBind[variable.selected_cmd].key)
												cmdBind[variable.selected_cmd].key = currentKey[2]
												rkeys.registerHotKey(currentKey[2], true, onHotKeyCMD)
												table.insert(keysList, currentKey[2])
												currentKey = {"",{}}
												lockPlayerControl(false)
												cb_RBUT.v = false
												cb_x1.v, cb_x2.v = false, false
												isHotKeyDefined = false
												imgui.CloseCurrentPopup();
												local f = io.open(adress.config.."/MedicalHelper/cmdSetting.json", "w")
												f:write(encodeJson(cmdBind))
												f:flush()
												f:close()
												editKey = false
											end					
										end
									end
									imgui.SameLine()
									if imgui.Button(u8"������", imgui.ImVec2(126, 0)) then
										lockPlayerControl(false)
										imgui.CloseCurrentPopup()
									end
								imgui.EndGroup()
							imgui.EndPopup()
							end
							imgui.PopStyleColor(1)
						end


					end
					if but.select_menu[4] then
						imgui.SetCursorPos(imgui.ImVec2(0, 0))
						imgui.BeginGroup()
							imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 1.0)
								if ButtonSettings(u8"���������", but.commands_settings[1]) then but.commands_settings = {true,false} end
									imgui.SameLine(132)
								if ButtonSettings(u8"����������", but.commands_settings[2]) then but.commands_settings = {false, true} end
							imgui.PopStyleVar()
								imgui.SetCursorPos(imgui.ImVec2(0, 30))
								imgui.Separator()
						imgui.EndGroup()

						if but.commands_settings[1] then
							imgui.SameLine(10)
							imgui.Spacing() imgui.Spacing()
							imgui.BeginGroup()
								imgui.Spacing()
								imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(0, 2))
								imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 0)
								imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 2))
								imgui.SameLine(0)
									imgui.BeginChild('#cset_1', imgui.ImVec2(181, 359), true)
										imgui.BeginGroup()
											for k, v in pairs(rptext) do
												
												if imgui.Selectable('  '..u8(('%s'):format(v.name)), but.cset == k) then
													but.cset = k
													buf_rp_name.v = u8(v.name)
													buf_rp.v = u8(v.text)
												end
											end
										imgui.EndGroup()
									imgui.EndChild()
									imgui.SameLine(187)
									imgui.BeginChild('#cset_2', imgui.ImVec2(529, 359), true)
										imgui.Spacing()
										imgui.SetCursorPos(imgui.ImVec2(0, 0))
										for k, v in pairs(rptext) do
											if but.cset == k then
												imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.16, 0.16, 0.16, 1.00))
												imgui.PushItemWidth(528)
													imgui.InputText("##mcedit2", buf_rp_name)
												imgui.PopItemWidth()
													imgui.InputTextMultiline("##mcedit", buf_rp, imgui.ImVec2(528, 298))
												imgui.PopStyleColor(1)
												imgui.Spacing() imgui.Spacing() imgui.Spacing()
												imgui.SameLine(8)
												imgui.BeginGroup()
													if imgui.Button(u8'���������', imgui.ImVec2(100, 20)) then 
														v.name = u8:decode(buf_rp_name.v)
														v.text = u8:decode(buf_rp.v)
														saveData(rptext, "moonloader/config/MedicalHelper/roleplay.json")
													end
													imgui.SameLine(104)
													if imgui.Button(u8'��������', imgui.ImVec2(100, 20)) then
														v.name = buf_rptext[k].name
														v.text = buf_rptext[k].text
														buf_rp_name.v = u8(v.name)
														buf_rp.v = u8(v.text)
														saveData(rptext, "moonloader/config/MedicalHelper/roleplay.json")
													end
												imgui.EndGroup()
											end
										end
									imgui.EndChild()
								imgui.PopStyleVar(3)
							imgui.EndGroup()
						end

						if but.commands_settings[2] then
							imgui.Spacing() imgui.Spacing()
							imgui.SameLine(16)
							imgui.BeginGroup()
								imgui.Text(u8'������ ����� ��� �������������� ���������:')
								imgui.Text(u8'{wait:0}') imgui.SameLine(100) imgui.Text(u8'- �������� � ������������� (������������� 1500);')
								imgui.Text(u8'{help:text}') imgui.SameLine(100) imgui.Text(u8'- ���������� ��������� � ������ ����;')
								imgui.Text(u8'{myID}') imgui.SameLine(100) imgui.Text(u8'- ID ������ ���������;')
								imgui.Text(u8'{myNick}') imgui.SameLine(100) imgui.Text(u8'- ����������� Nick ������ ��������� ��� "_";')
								imgui.Text(u8'{myNick2}') imgui.SameLine(100) imgui.Text(u8"- ������� Nick'a (��� ������� / ��� / ������� / �������), ��������� � ����;")
								imgui.Text(u8'{RusNick}') imgui.SameLine(100) imgui.Text(u8'- ��� ������ ��������� �� ������� (���� ���� �������);')
								imgui.Text(u8'{myClist}') imgui.SameLine(100) imgui.Text(u8'- ����� ������ ����� (/clist);') 
								imgui.Text(u8'{myTag}') imgui.SameLine(100) imgui.Text(u8'- ��� ���, ������������ � ����;')
								imgui.Text(u8'{myRank}') imgui.SameLine(100) imgui.Text(u8'- ��� ���� �� ���������� ���������;')
								imgui.Text(u8'{time}') imgui.SameLine(100) imgui.Text(u8'- ������� �����;')
								imgui.Text(u8'{day}') imgui.SameLine(100) imgui.Text(u8'- ������� ����� (1-31);') 
								imgui.Text(u8'{myHP}') imgui.SameLine(100) imgui.Text(u8'- ������� ������ ��������;')
								imgui.Text(u8'{myArm}') imgui.SameLine(100) imgui.Text(u8'- ������� ������ �����������;') 
								imgui.Text(u8'{pID}') imgui.SameLine(100) imgui.Text(u8'- ID ���������� ������;') 
								imgui.Text(u8'{pNick}') imgui.SameLine(100) imgui.Text(u8'- ����������� Nick ���������� ������ ��� "_";')
								imgui.Text(u8'{sex}') imgui.SameLine(100) imgui.Text(u8'- �������������� ����������� "�" � ��������� � ����������� �� ����;')
								imgui.Text(u8'{sex2}') imgui.SameLine(100) imgui.Text(u8'- �������������� ����������� "��" � ��������� � ����������� �� ����;')
							imgui.EndGroup()
						end
					end
					if but.select_menu[5] then
						imgui.CenterText(u8'�������')
						imgui.Spacing()
						imgui.Separator()
						imgui.Spacing()
						imgui.BeginGroup()
							imgui.Spacing()
							imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(0, 2))
							imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 0)
							imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 2))
								imgui.SameLine(0)
								imgui.BeginChild('#notelist', imgui.ImVec2(181, 359), true)
									imgui.BeginGroup()
										for k, v in pairs(table_note) do
											if imgui.Selectable(u8(('  %s'):format(v.name)), but.nset == k) then
												but.nset = k
												buf_note_name.v = u8(v.name)
												buf_note.v = u8(v.text)
											end
										end 
									imgui.EndGroup()
								imgui.EndChild()
								imgui.SameLine(187)
								imgui.BeginChild('#notetext', imgui.ImVec2(529, 359), true)
									imgui.Spacing()
									imgui.SetCursorPos(imgui.ImVec2(0, 0))
									for k, v in pairs(table_note) do
										if but.nset == k then
											imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.16, 0.16, 0.16, 1.00))
												imgui.PushItemWidth(528)
													imgui.InputText("##mcedit2", buf_note_name)
												imgui.PopItemWidth()
												imgui.InputTextMultiline("##mcedit", buf_note, imgui.ImVec2(528, 298))
											imgui.PopStyleColor(1)
											imgui.Spacing() imgui.Spacing() imgui.Spacing()
											imgui.SameLine(8)
											imgui.BeginGroup()
												if imgui.Button(u8'���������', imgui.ImVec2(100, 20)) then 
													v.name = u8:decode(buf_note_name.v)
													v.text = u8:decode(buf_note.v)
													saveData(table_note, "moonloader/config/MedicalHelper/note.json")
												end
												imgui.SameLine(104)
												if imgui.Button(u8'��������', imgui.ImVec2(100, 20)) then
													v.name = buf_table_note[k].name
													v.text = buf_table_note[k].text
													buf_note_name.v = u8(v.name)
													buf_note.v = u8(v.text)
													saveData(table_note, "moonloader/config/MedicalHelper/note.json")
												end
											imgui.EndGroup()
										end
									end
								imgui.EndChild()
							imgui.PopStyleVar(3)
						imgui.EndGroup()
					end

				imgui.EndChild()

			imgui.EndChild()
			imgui.Spacing()
			imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 31)
			imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.25, 0.25, 0.25, 1.00))
			imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.14, 0.14, 0.14, 1.00))
			imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.25, 0.25, 0.25, 1.00))
			imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
			imgui.SetCursorPosX(400 - 21)
				if imgui.Button(fa.ICON_TIMES, imgui.ImVec2(21, 21)) then
					needsave()
					inicfg.save(col, adress.col)
					buffer.nh_menu.v = false
				end
			imgui.PopStyleColor(4)
			imgui.PopStyleVar()



		imgui.End()
	end
------------------------------------- ���������� ���� �������� --------------------------------

--[[	imgui.BeginGroup()
			imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 1.0)
			imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10, 0.10, 0.10, 1.00))
			imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18, 0.18, 0.18, 1.00))
			imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
			imgui.SetCursorPos(imgui.ImVec2(0, 0))
			if imgui.Button(u8'����������', imgui.ImVec2(120, 30)) then menu2 = 1 end
				imgui.PopStyleColor(3)
				imgui.PopStyleVar()
		imgui.EndGroup()
		imgui.SetCursorPos(imgui.ImVec2(0, 30))
		imgui.Separator()
		imgui.BeginChild('##menu2_1', imgui.ImVec2(714, 364), true)
			if menu2 == 1 then
				window_members()
			end
		imgui.EndChild()			]]
	
end

function menu_stats()
	imgui.BeginChild('#nhstats', imgui.ImVec2(320, 266), true)
		imgui.Text(u8'1. ��������:')
		imgui.Separator()
		imgui.Columns(2)
			imgui.Text(fa.ICON_USER.. u8' ���:')
			imgui.Text(fa.ICON_LEVEL_UP.. u8' �������:')
			imgui.Text(fa.ICON_GENDERLESS.. u8' ���:')
			imgui.Text(fa.ICON_BRIEFCASE.. u8' �����������:')
			imgui.Text(fa.ICON_GRADUATION_CAP.. u8' �������������:')
			imgui.Text(fa.ICON_COFFEE.. u8' ������:')
		imgui.NextColumn()
			imgui.Text(nickname)
			imgui.Text(score.. ' [' ..u8(tostring(u8:decode(chgName.stats[1]))).. ']')
			imgui.Text(u8(tostring(u8:decode(chgName.stats[2]))))
			imgui.Text(u8(tostring(u8:decode(chgName.stats[3]))))
			imgui.Text(u8(tostring(u8:decode(chgName.stats[4]))..' ['..tostring(u8:decode(chgName.stats[5]))..']'))
			imgui.Text(u8(tostring(u8:decode(chgName.stats[6]))))
		imgui.Columns(1) 
		imgui.Separator()
		imgui.Spacing()
		imgui.Text(u8'2. ��������������:')
		imgui.Separator()	
		imgui.Text(u8'���������:')
		imgui.SameLine()
			post()
	imgui.EndChild()
end

function sampev.onServerMessage(color, message)
	local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	local nickname = sampGetPlayerNickname(my_id)
	--[[
			[12:00:10] --------===[ ������ ����� SA ]===-------
			[12:00:10] ***** ����� �����������: -350 ���� *****
			[12:00:10]  ���� �� �������: -40 ����
			[12:00:10]  
			[12:00:10]  ��������: 6658 ����
			[12:00:10]  ������� ������: 28251 ����
			[12:00:10] ==============[11:00]==============
	]]
	if message:find("--------===%[ (.+) %]===-------") then
		variable.pstats = 1
		variable.value_zp = 0
		return false
	end
	if message:match("����� "..nickname.." ������� .+") then
		medWork.heal_all = medWork.heal_all + 1
		medWork.heal_post = medWork.heal_post + 1
	end
	if message:match("�������� ���������") then
		medWork.medcard_all = medWork.medcard_all + 1
		medWork.medcard_post = medWork.medcard_post + 1
	end
	if message:match("�������� �������") then
		medWork.medcard_all = medWork.medcard_all + 1
		medWork.medcard_post = medWork.medcard_post + 1
	end
	if message:match("�� �������� �������� .+") then
		medWork.heal_all = medWork.heal_all + 1
		medWork.heal_post = medWork.heal_post + 1
	end
	if message:match("������� ������� �� ������� .+") then
		medWork.heal_all = medWork.heal_all + 1
		medWork.heal_post = medWork.heal_post + 1
	end
	if message:match("����� ������� �� ������� .+") then
		medWork.heal_all = medWork.heal_all + 1
		medWork.heal_post = medWork.heal_post + 1
	end
	
	if variable.check_zp == 2 and message:find(" �� �����!") then variable.check_zp = 1 end
	--  �� ���������� 3504 ����. ������ ����� ��������� �� ��� ���������� ���� � 00:00
	if variable.check_zp == 2 and message:find(" �� ���������� (%d+) .+%. ������ ����� ��������� �� ��� ���������� ���� � .+") then
		variable.check_zp = 0
		variable.value_zp = message:match(" �� ���������� (%d+) .+%. ������ ����� ��������� �� ��� ���������� ���� � .+")
		return false
	end
	-- [���������] {FFFFFF}Zhenya_Marchev[81]: test
	if col.Colors.active_sqchat == true then
		if message:find(' %[(.+)%] {FFFFFF}(%w+_%w+)%[(%d+)%]: (.+)') then
			local sqrank, sqnick, sqid, sqmsg = message:match(' %[(.+)%] {FFFFFF}(%w+_%w+)%[(%d+)%]: (.+)')
			sampAddChatMessage(' ['..sqrank..'] '..sqnick..' ['..sqid..']: '..sqmsg, col.Colors.col_sqchat)
			return false
		end
	end
	-- [FBI] ����� DEA  Konstantin_Fridrikh[252]:  Army LV, ������� �� ���� ����������.
	if col.Colors.active_dep == true then
		if message:find(' %[%D+%] .+ %a+_%a+%[%d+%]: .+') then
			sampAddChatMessage(message, col.Colors.col_dep)
			return false
		end
	end

	--  [Army LV] ��.�������  Eduard_Ryder[415]:  Af, ���� ��. ����� ������������! // departament
	if col.Colors.active_fchat == true then
		--  ���.��������  Zhenya_Marchev[0]:  asdasdasdasdwqe
		if message:find(' (.+)  (%w+_%w+)%[(%d+)%]:  (.+)') then
			if not message:find('%[Mayor%]') and not message:find('%[Court%]') and not message:find('%[Police %a+%]') and not message:find('%[Army %a+%]') and not message:find('%[Medic%]') and not message:find('%[Instructors%]') then
				local frank, fnick, fid, fmsg = message:match(' (.+)  (%w+_%w+)%[(%d+)%]:  (.+)')
				sampAddChatMessage(frank.. ' ' ..fnick.. ' [' ..fid.. ']: ' ..fmsg, col.Colors.col_fchat)
				return false
			end
		end
	end
	if col.Colors.active_sms == true then
		--  SMS: ������ ��� ����. ����������: Sonya_Falcone
		if message:find(' SMS: (.+)%. ����������: (.+)') then
			local smsg, snick = message:match(' SMS: (.+)%. ����������: (.+)')
			sampAddChatMessage(' SMS: ' ..smsg.. '. ����������: ' ..snick, col.Colors.col_sms)
			return false
		end
		if message:find(' ��������� ����������') and not message:find('%w+') then
			sampAddChatMessage(' ��������� ����������', col.Colors.col_sms)
			return false
		end
		if message:find(' SMS: (.+)%. �����������: (.+)') then
			local smsg, snick = message:match(' SMS: (.+)%. �����������: (.+)')
			sampAddChatMessage(' SMS: ' ..smsg.. '. �����������: ' ..snick, col.Colors.col_sms)
			return false
		end
	end
	if string.find(message, " �� ������� � .+ ������� .+") then
		variable.pstats = 1
	end
	if string.find(message, " .+ ������ ��� �� �����������%. �������: .+") then
		variable.pstats = 1
	end 
	if string.find(message, " .+ �������/������� ��� �� %d+ �����") then
		variable.pstats = 1
	end
	if string.find(message, ' ������� ���� �������') then
		variable.pstats = 1
	end
	if string.find(message, ' ������� ���� �����') then
		ms = math.ceil(os.clock() * 1000 - variable.antiflood)
		if ms > 1800 then
			if buffer.actg.v then
				lua_thread.create(function()
					wait(2000)
					sampSendChat("/clist "..buffer.buf_Clist)
					wait(1000)
				end)
			end
		end
		variable.pstats = 1
	end

--ID: 212 | 22:16 02.02.2023 | Petr_Rostovskiy (Voice): ��������[6] - {ae433d}��������{FFFFFF} | {FFFFFF}[AFK]: 221 ������
--[[	if mcheck then
		if message:find(" ID: %d+ | .+ | %g+.+: .+%[%d+%] %- %{......%}.+%{......%}") then
			if not message:find("AFK") then
				local mid, invDate, name, sRang, iRang, status = message:match(" ID: (%d+) | (.+) | (%g+).+: (.+)%[(%d+)%] %- %{.+%}(.+)%{.+%}")
				table.insert(mt, Player:new(mid, sRang, iRang, status, invDate, false, 0, name))
			else
				local mid, invDate, name, sRang, iRang, status, sec = message:match("ID: (%d+) | (.+) | (%g+).+: (.+)%[(%d+)%] %- %{.+%}(.+)%{.+%} | %{.+%}%[AFK%]: (%d+).+")
				table.insert(mt, Player:new(mid, sRang, iRang, status, invDate, true, sec, name))
			end
		end
		if message:find("�����: %d+ �������") then
			mcheck = false
		end
		return false
	end]]
	if buffer.OffAdm.v == true then
		if message:find(" �������������: (.+) ����� warn (.+)%. �������(.+)") then
			local admin, player, reason = message:match(" �������������: (.+) ����� warn (.+)%. �������(.+)")
			if player == nickname then
				sampAddChatMessage(" �������������: "..admin.." ����� warn "..player..". �������"..reason, CL.COLOR_ADM)
			end
			return false
		end
		--  �������������: Fernando_Berg ������� � �������� Lil_Carter. �������: db, ������ ������.
		if message:find(" �������������: (.+) ������� � �������� (.+)%. �������(.+)") then
			local admin, player, reason = message:match(" �������������: (.+) ������� � �������� (.+)%. �������(.+)")
			if player == nickname then
				sampAddChatMessage(" �������������: "..admin.." ������� � �������� "..player..". �������"..reason, CL.COLOR_ADM)
			end
			return false
		end

		if message:find(" �������������: (.+) ������ (.+)%. �������(.+)") then
			local admin, player, reason = message:match(" �������������: (.+) ������ (.+)%. �������(.+)")
			if player == nickname then
				sampAddChatMessage(" �������������: "..admin.." ������ "..player..". �������"..reason, CL.COLOR_ADM)
			end
			return false
		end

		--  Desert_Eagle �������(�) ��� ���� �� �������������� Evgeny_Roizman. �������: ��� | [-40121] {FF6347}
		--  Jeka_Zab �������(�) ��� ���� �� �������������� Davide_Cooper. �������: flood
		--  Ririka_Oomori �������(�) ��� ���� �� �������������� Pavel_Pustyakov. �������: osk
		--  Bartolomeo_Derozan �������(�) ��� ���� �� �������������� Martin_Robbens. �������: ���������
		if message:find(" (.+) �������%(�%) ��� ���� �� �������������� (.+)%. �������(.+)") then
			local player, admin, reason = message:match(" (.+) �������%(�%) ��� ���� �� �������������� (.+)%. �������(.+)")
			if player == nickname then
				sampAddChatMessage(player.." �������(�) ��� ���� �� �������������� "..admin..". �������"..reason, CL.COLOR_ADM)
			end
			return false
		end
		--  ������������� Tim_Bredford ���� ��� ���� � Danil_Nicolaev
		if message:find(" ������������� (.+) ���� ��� ���� � (.+)") then
			local admin, player = message:match(" ������������� (.+) ���� ��� ���� � (.+)")
			if player == nickname then
				sampAddChatMessage(" ������������� "..admin.." ���� ��� ���� � "..player, CL.COLOR_ADM)
			end
			return false
		end
		--  �������������: Tim_Bredford ������� Vlados_Shkaf [3 ��������������]. �������: aimbot  [Rifa / 7]
		if message:find(" �������������: (.+) ������� (.+) %[3 ��������������%]%. �������(.+)") then
			local admin, player, reason = message:match(" �������������: (.+) ������� (.+) %[3 ��������������%]%. �������(.+)")
			if player == nickname then
				sampAddChatMessage(" �������������: "..admin.." ������� "..player.." [3 ��������������]. �������"..reason, CL.COLOR_ADM)
			end
			return false
		end
		-- �������������: Johnny_Hart ������� Bdoglnya_spmel4lomoR. �������: bot.
		if message:find(" �������������: (.+) ������� (.+)%. �������(.+)") then
			local admin, player, reason = message:match(" �������������: (.+) ������� (.+)%. �������(.+)")
			if player == nickname then
				sampAddChatMessage(" �������������: "..admin.." ������� "..player..". �������"..reason, CL.COLOR_ADM)
			end
			return false
		end
	end
	
	--  ����������: ������ ���-�������. ��������: Vira_Nech. ���: 309003
	-- �������� News LV. ��������������: Edward_Ozeransky
	local buf_newstext, buf_newsmyname, buf_newsnumber = "", "", ""
	if buffer.OffA.v == true and message:find(" ����������: (.+) �������: (.+)%. ���: (%d+)") then
		buf_newstext, buf_newsmyname, buf_newsnumber = message:match(" ����������: (.+) �������: (.+)%. ���: (%d+)")
		return false
	end

	if buffer.OffA.v == true and message:find(" ����������: (.+) ��������: (.+)%. ���: (%d+)") then
		buf_newstext, buf_newsmyname, buf_newsnumber = message:match(" ����������: (.+) ��������: (.+)%. ���: (%d+)")
		return false
	end

	--         �������� News LV. ��������������: Aaron_Ramsey
	local buf_newsnews, buf_newsplayer = "", ""
	if buffer.OffA.v == true and message:find("        �������� News (.+) ��������������(.+)") then
		buf_newsnews, buf_newsplayer = message:match("        �������� News (.+) ��������������(.+)")
		return false
	end
	--        �������� News LS. �������� ��������: Hayden_Coleman
	if buffer.OffA.v == true and message:find("        �������� News (.+) �������� ��������(.)") then
		buf_newsnews, buf_newsplayer = message:match("        �������� News (.+) �������� ��������(.)")
		return false
	end

	if buffer.OffA.v == true and buf_newsmyname == nickname then
		sampAddChatMessage(" {00FF00}����������: "..buf_newstext.." �������(�): "..buf_newsmyname..". ���: "..buf_newsnumber, CL.COLOR_GREEN)
		sampAddChatMessage("        �������� News "..buf_newsnews.." ��������������"..buf_newsplayer, CL.COLOR_GREEN)
		buf_newsmyname = ""
	end

	-- -----------=== ��������������� ������� ===-----------
	-- �������: Arthyr_Shelby: [SFA]: ��������� ����� - ��������� SF. ��� ����� ����� �� GPS ���������� [0] - [22].
	if buffer.OffG.v == true then
		if message:find(" -----------=== ��������������� ������� ===-----------") or message:find("�������: %w+_%w+: .+") then			
		 	return false
		end
	end

	if buffer.OffC.v == true then
		if message:find(" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~") then
			return false
		end
		if message:find(" ������� ��� ������ � ��������� ������� .+") then
			return false
		end
		if message:find(" ������� ������ � ������� �� ������������ ����� Samp RolePlay .+") then
			return false
		end -- ��� ������������ ��� ���������� �� ������ �������� �� ����� - samp-rp.ru
		if message:find(" ��� ������������ ��� ���������� �� ������ �������� �� ����� .+") then
			return false
		end
	end
end

function onHotKeyCMD(id, keys)
	if thread:status() == "dead" then
		local sKeys = tostring(table.concat(keys, " "))
		for k, v in pairs(cmdBind) do
			if sKeys == tostring(table.concat(v.key, " ")) then
				if k == 1 then
					buffer.nh_menu.v = not buffer.nh_menu.v
				elseif k == 2 then
					clickmenu_imgui()
				elseif k == 3 then
					sampSetChatInputEnabled(true)
					if buffer.buf_OnTag.v == true and buffer.buf_tag ~= "" then
						sampSetChatInputText("/r "..u8:decode(buffer.buf_tag).." ")
					elseif buffer.buf_OnTag.v == false then
						sampSetChatInputText("/r ")
					end
				end
			end
		end
	else
		sampAddChatMessage("{FFFFFF}[{EE4848}MedicalHelper{FFFFFF}]: � ������ ������ ������������� ���������.", 0xEE4848)
	end
end

function clickmenu_imgui()
	if buffer.Offcl.v == true then
		lua_thread.create( function()
			buffer.clmenu.v = not buffer.clmenu.v
				if buffer.clmenu.v == true then
					checkoncar()
					but.select_button[10] = not but.select_button[10]
					buffer.clmenu_nicks.v = not buffer.clmenu_nicks.v
				else
					buffer.clmenu_nicks.v = false
					venick.p_id = 0
					veh_pid = {}
					but.select_button = {false, false, false, false, false, false, false, false, false, false, false}
				end
		end)
	end	
end

function FileAd(int, AdString)
	if int == 0 and AdString ~= nil then
		local file = io.open(adress.chatlog, "a")
		file:write("["..os.date("%d.%m.%Y").." | "..os.date("%X",os.time()).."] "..AdString.."\n")
		file:flush()
		io.close(file)
	end
end

function sampev.onShowDialog(DdialogId, Dstyle, Dtitle, Dbutton1, Dbutton2, Dtext)
	if Dstyle == 4 and Dtitle == "���������� ���������" and variable.pstats == 2 then
		local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local Exp1 = string.match(Dtext, 'Exp\t+(%d+ / %d+)\nVIP')
		local aSex = string.match(Dtext, '���\t+(.+)\n�����������')
		local Orga = string.match(Dtext, '�����������\t+(.+)\n����')
		local findRank = string.match(Dtext, '����\t+(.+)\n������')
		local aRank = "���"; local number_rank = 0
		if findRank:find('(.+) %[(%d+)%]') then
			aRank, number_rank = string.match(findRank, '(.+) %[(%d+)%]')
		end
		local aJob = string.match(Dtext, '������\t+(.+)\n����/���')
		chgName.stats = {u8(Exp1), u8(aSex), u8(Orga),  u8(aRank), number_rank, u8(aJob)}
		needsave()
		variable.pstats = 0
		chsex()
		return false
	end
end

function ButtonMenu(desk, bool) -- ��������� ������ ���������� ����
	local retBool = false
	if bool then
		imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 0.21, 0.21, 1.00))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.00, 0.21, 0.21, 1.00))
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.00, 0.21, 0.21, 1.00))
			retBool = imgui.Button(desk, imgui.ImVec2(51, 39))
		imgui.PopStyleColor(3)
	elseif not bool then
		imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10, 0.10, 0.10, 1.00))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18, 0.18, 0.18, 1.00))
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
			retBool = imgui.Button(desk, imgui.ImVec2(51, 39))
		imgui.PopStyleColor(3)
	end
	return retBool
end

function ButtonSettings(desk, bool)
	local retBool = false
	if bool then
		imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
			retBool = imgui.Button(desk, imgui.ImVec2(130, 30))
		imgui.PopStyleColor(3)
	elseif not bool then
		imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10, 0.10, 0.10, 1.00))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18, 0.18, 0.18, 1.00))
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
			retBool = imgui.Button(desk, imgui.ImVec2(130, 30))
		imgui.PopStyleColor(3)
	end
	return retBool
end

function filter(mode, filderChar)
	local function locfil(data)
		if mode == 0 then --
			if string.char(data.EventChar):find(filderChar) then 
				return true
			end
		elseif mode == 1 then
			if not string.char(data.EventChar):find(filderChar) then 
				return true
			end
		end
	end 
	
	local cbFilter = imgui.ImCallback(locfil)
	return cbFilter
end

function parseMembers()
	mt = {}
	variable.mcheck = true
	sampSendChat("/members")
end

function Player:new(pid, sRang, iRang, status, invite, afk, sec, nick)
	local obj = {
		mid = pid,
		name = nick,
		iRang = tonumber(iRang),
		sRang = u8(sRang),
		status = u8(status),
		invite = invite,
		afk = afk,
		sec = tonumber(sec)
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function sampev.onSendChat(message) variable.antiflood = os.clock() * 1000 end

function imgui.Hint(text, delay)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 5 -- �������� ���������
        if os.clock() >= go_hint then
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.ImVec4(0.14, 0.14, 0.14, 1.00))
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextUnformatted(text)
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar()
        end
    end
end

function ask()
	imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.5, 0.5, 0.5, 1.00))
		imgui.Text(fa.ICON_QUESTION_CIRCLE)
	imgui.PopStyleColor()	
end

function timer()
	local need_time = os.date("%M:%S", os.time())
	local timer_zp = {"01:44", "06:44", "11:44", "16:44", "21:44", "26:44", "31:44", "36:44", "41:44", "46:44", "51:44", "56:44"}
	lua_thread.create(function()
		for k, v in pairs(timer_zp) do
			if need_time == v then
				wait(5000)
				variable.check_zp = 1
			end
		end
	end)
end

function number_week()
    local current_time = os.date'*t'
    local start_year = os.time{ year = current_time.year, day = 1, month = 1 }
    local week_day = ( os.date('%w', start_year) - 1 ) % 7
    return math.ceil((current_time.yday + week_day) / 7)
end

function DightNum(num)
    if math.floor(num) ~= num or num < 0 then
        return -1
    elseif 0 == num then
        return 1
    else
        local tmp_dight = 0
        while num > 0 do
            num = math.floor(num/10)
            tmp_dight = tmp_dight + 1
        end
        return tmp_dight
    end
end

function AddZeroFrontNum(dest_dight, num)
    local num_dight = DightNum(num)
    if -1 == num_dight then
        return -1
    elseif num_dight >= dest_dight then
        return tostring(num)
    else
        local str_e = ""
        for var =1, dest_dight - num_dight do
            str_e = str_e .. "0"
        end
        return str_e .. tostring(num)
    end
end

function imgui.AllCenterText(text)
	local width = imgui.GetWindowWidth()
    local height = imgui.GetWindowHeight()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX(width / 2 - calc.x / 2, height / 2 + calc.y / 2)
    imgui.Text(text)
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX(width / 2 - calc.x / 2)
    imgui.Text(text)
end

function imgui.RightText(text)
	local width = imgui.GetWindowWidth()
	local calc = imgui.CalcTextSize(text)
	imgui.SetCursorPosX(width - calc.x)
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4
    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end
    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end
    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end

function string.nlower(s)
    s = lower(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = ul_rus[ch] or ch
    end
    return concat(res)
end

function string.nupper(s)
    s = upper(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = lu_rus[ch] or ch
    end
    return concat(res)
end

function check_skin_local_player()
	local result = false
	for k,v in pairs(skins) do
		if isCharModel(PLAYER_PED, v) then
			result = true
			break
		end
	end
	return result
end

MedicClists = { 2863857664, 2857434774, 2863857664, 2853039615, 2868880928, 2853375487, 2860620717 }
function autoclist()
--	if check_skin_local_player() then
		local myclist = sampGetPlayerColor(my_id)
		while myclist == 2862896983 do
			sampSendChat("/clist "..buffer.buf_Clist)
			wait(5000)
			break
		end
--	end
end

function rkeys.onHotKey(id, keys)
	if sampIsChatInputActive() or sampIsDialogActive() or isSampfuncsConsoleActive() or buffer.nh_menu.v and editKey then
		return false
	end
end

function NameFormat()
	if nickname:find("(.+)_(.+)") then
		Name, Surname = nickname:match('(.+)_(.+)')
	end
	chgName.uname = {'1. '..tostring(Name..' '..Surname), '2. '..tostring(Name), '3. '..tostring(Surname), u8"4. ����������������"}
end

--[[function clickmenu()
	if isKeyDown(VK_RBUTTON) then
		local X, Y = getScreenResolution()
		Y = Y / 3
		X = X - renderGetFontDrawTextLength(font, " ")
		if not r.mouse then
			r.mouse = true
			r.ShowCMD = false
		end
		showCursor(true)
		Y = ((Y + renderGetFontDrawHeight(font)) + (renderGetFontDrawHeight(font) / 10))
		rtext = "�������� �����"
		if ClickTheText(font, rtext, (X - renderGetFontDrawTextLength(font, rtext.."  ")), Y, 0xFFFFFFFF, 0xFFFFFFFF) then
			sampAddChatMessage("�� ������ �� �������� �����", -1)
		end
	else
		if r.mouse then
			r.mouse = false
			r.ShowClients = false
			showCursor(false)
		end
	end
end

function ClickTheText(font, text, posX, posY, color, colorA)
	renderFontDrawText(font, text, posX, posY, color)
	local textLenght = renderGetFontDrawTextLength(font, text)
	local textHeight = renderGetFontDrawHeight(font)
	local curX, curY = getCursorPos()
	if curX >= posX and curX <= posX + textLenght and curY >= posY and curY <= posY + textHeight then
	  renderFontDrawText(font, "{ff2e2e}" ..text, posX, posY, colorA)
	  if isKeyJustPressed(1) then
		return true
	  end
	end
end]]
 
function SelectButtonMenu(desk, bool)
	local retBool = false
	if bool then
			retBool = imgui.Button(desk, imgui.ImVec2(26, 26))
	elseif not bool then
			retBool = imgui.Button(desk, imgui.ImVec2(26, 26))
	end
	return retBool
end

function needsave()
	Settings.Tag = buffer.num_tag.v
	Settings.Clist = buffer.buf_Clist
	Settings.UserName = u8:decode(buffer.buf_nick.v)
	Settings.select_name = buffer.namenumber.v
	Settings.Show_Stats = buffer.stats_imgui.v
	Settings.Show_sstats = buffer.sstats.v
	Settings.Show_smap = buffer.smap.v
	Settings.Plus_Chat = buffer.pluschat.v
	Settings.Plus_Size = psize.v
	Settings.Plus_Number = buffer.pnumber.v
	Settings.Autoclist = buffer.actg.v
	Settings.OffAdds = buffer.OffA.v
	Settings.OffGov = buffer.OffG.v
	Settings.select_streets = buffer.sstr.v
	Settings.x_stats = coords.buf_x_stats
	Settings.y_stats = coords.buf_y_stats
	Settings.x_pluschat	= coords.buf_x_pluschat
	Settings.y_pluschat	= coords.buf_y_pluschat
	Settings.x_select = coords.buf_x_select
	Settings.y_select = coords.buf_y_select
	Settings.OffAdmins = buffer.OffAdm.v
	Settings.OnTag = buffer.buf_OnTag.v
	Settings.bTag = u8:decode(buffer.buf_tag)
	Settings.OffClue = buffer.OffC.v
	Settings.Offclmenu = buffer.Offcl.v
	Settings.tagl = {}
	for i,v in ipairs(chgName.tag) do
		Settings.tagl[i] = u8:decode(v)
	end
	Settings.statsl = {}
	for i, v in ipairs(chgName.stats) do
		Settings.statsl[i] = u8:decode(v)
	end
	Settings.clistl = {}
	for i, v in ipairs(chgName.clist) do
		Settings.clistl[i] = u8:decode(v)
	end
	local f = io.open(adress.config.."/MedicalHelper/Settings.json", "w")
	f:write(encodeJson(Settings))
	f:flush()
	f:close()
end

function tags(par)
		par = par:gsub("{myID}", tostring(my_id))
		par = par:gsub("{myNick}", tostring(sampGetPlayerNickname(my_id):gsub("_", " ")))
		par = par:gsub("{myNick2}", tostring(u8(variable.sname)))
		par = par:gsub("{RusNick}", tostring(u8:decode(buffer.buf_ru_nick)))
		par = par:gsub("{myHP}", tostring(getCharHealth(PLAYER_PED)))
		par = par:gsub("{myArm}", tostring(getCharArmour(PLAYER_PED)))
		par = par:gsub("{myClist}", buffer.buf_Clist)
		--par = par:gsub("{myHosp}", tostring(u8:decode(chgName.org[num_org.v+1])))
		-- par = par:gsub("{myHospEn}", tostring(u8:decode(list_org_en[num_org.v+1])))
		par = par:gsub("{myTag}", tostring(u8:decode(buffer.buf_tag)))
		par = par:gsub("{myRank}", tostring(u8:decode(chgName.stats[4])))
		par = par:gsub("{time}", os.date("%X"))
		par = par:gsub("{day}", os.date("%d"))
		par = par:gsub("{pID}", venick.p_id)
		par = par:gsub("{pNick}", tostring(venick.p_nick:gsub("_", " ")))
		par = par:gsub("{sex}", achsex)
		par = par:gsub("{sex2}", achsex2)
		--par = par:gsub("{week}", tostring(week[tonumber(os.date("%w"))]))
		--par = par:gsub("{month}", tostring(month[tonumber(os.date("%m"))]))
	return par
end

function checkOnTag()
	if buffer.buf_OnTag.v == true and buffer.buf_tag ~= "" then return true else return false end
end
 --��� ����.�����  Molly_Davis[500]:  (( ���. ������ 11 �����.. ))
function started()
	if calculateHospital() then
		sampSetChatInputEnabled(true)
		if checkOnTag() then
			sampSetChatInputText("/r [" ..u8:decode(buffer.buf_tag).. "] ������������: ?")
		else
			sampSetChatInputText("/r ������������: ?")
		end	
	else
		if calculatePost() then 
			if variable.partner ~= "" then
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] �������� �� ����: " ..calculatePost().. ". ��������: " ..variable.partner) 
				else
					sampSendChat("/r �������� �� ����: " ..calculatePost().. ". ��������: " ..variable.partner) 
				end
			else
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] �������� �� ����: " ..calculatePost()) 
				else
					sampSendChat("/r �������� �� ����: " ..calculatePost())
				end
			end
		else 
			if variable.partner ~= "" then
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] �������� � �������: " ..calculateCity(2).. ". ��������: " ..variable.partner) 
				else
					sampSendChat("/r �������� � �������: " ..calculateCity(2).. ". ��������: " ..variable.partner) 
				end
			else
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] �������� � �������: " ..calculateCity(2)) 
				else
					sampSendChat("/r �������� � �������: " ..calculateCity(2)) 
				end
			end
		end
	end
end

function doklad()
	if calculateHospital() then
		sampSetChatInputEnabled(true)
		if checkOnTag() then
			sampSetChatInputText("/r [" ..u8:decode(buffer.buf_tag).. "] ������������: ?")
		else
			sampSetChatInputText("/r ������������: ?")
		end	
	else
		if calculatePost() then 
			if variable.partner ~= "" then
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] ����: " ..calculatePost().. ". ��������: " ..variable.partner.. ". ���������: " ..medWork.heal_post) 
				else
					sampSendChat("/r ����: " ..calculatePost().. ". ��������: " ..variable.partner.. ". ���������: " ..medWork.heal_post) 
				end
			else
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] ����: " ..calculatePost().. ". ���������: " ..medWork.heal_post) 
				else
					sampSendChat("/r ����: " ..calculatePost().. ". ���������: " ..medWork.heal_post) 
				end
			end
		else 
			if variable.partner ~= "" then
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] �������: " ..calculateCity(2).. " [" ..calculateSquare().. "]. ��������: " ..variable.partner.. ". ���������: " ..medWork.heal_post) 
				else
					sampSendChat("/r �������: " ..calculateCity(2).. " [" ..calculateSquare().. "]. ��������: " ..variable.partner.. ". ���������: " ..medWork.heal_post) 
				end
			else
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] �������: " ..calculateCity(2).. " [" ..calculateSquare().. "]. ���������: " ..medWork.heal_post) 
				else
					sampSendChat("/r �������: " ..calculateCity(2).. " [" ..calculateSquare().. "]. ���������: " ..medWork.heal_post) 
				end
			end
		end
	end
end

function finished()
	if calculateHospital() then
		sampSetChatInputEnabled(true)
		if checkOnTag() then
			sampSetChatInputText("/r [" ..u8:decode(buffer.buf_tag).. "] ������������: ?")
		else
			sampSetChatInputText("/r ������������: ?")
		end	
	else
		if calculatePost() then 
			if variable.partner ~= "" then
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] ������� ����: " ..calculatePost().. ". ��������: " ..variable.partner.. ". ���������: " ..medWork.heal_post) 
				else
					sampSendChat("/r ������� ����: " ..calculatePost().. ". ��������: " ..variable.partner.. ". ���������: " ..medWork.heal_post) 
				end
			else
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] ������� ����: " ..calculatePost().. ". ���������: " ..medWork.heal_post) 
				else
					sampSendChat("/r ������� ����: " ..calculatePost().. ". ���������: " ..medWork.heal_post) 
				end
			end
		else 
			if variable.partner ~= "" then
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] �������� �������: " ..calculateCity(2).. ". ��������: " ..variable.partner.. ". ���������: " ..medWork.heal_post) 
				else
					sampSendChat("/r �������� �������: " ..calculateCity(2).. ". ��������: " ..variable.partner.. ". ���������: " ..medWork.heal_post) 
				end
			else
				if checkOnTag() then
					sampSendChat("/r [" ..u8:decode(buffer.buf_tag).. "] �������� �������: " ..calculateCity(2).. ". ���������: " ..medWork.heal_post) 
				else
					sampSendChat("/r �������� �������: " ..calculateCity(2).. ". ���������: " ..medWork.heal_post) 
				end
			end
		end
	end
	medWork.heal_post = 0
end

---------------------------------------------- imgui ������� -----------------------------------------------

function imgui_clmenu()
	local sizetext = 0
	local nick_x, nick_y = 0, 0
	if #veh_pid == 0 then sizetext = 18 else sizetext = tonumber(#veh_pid) * 16 + tonumber(#veh_pid) * 2 end
	imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2,2))
	imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 0)
	imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(1.0, 1.0, 1.0, 0.0))
	imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.04, 0.04, 0.04, 0.45))
	imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.05, 0.05, 0.05, 0.63))
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.13, 0.13, 0.13, 0.63))
	imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.3, 0.3, 0.3, 0.45))
	imgui.SetNextWindowPos(imgui.ImVec2(coords.buf_x_select, coords.buf_y_select), imgui.Cond.Always)
	imgui.Begin('##clickmenu', buffer.clmenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse  + imgui.WindowFlags.AlwaysAutoResize)
		imgui.PushFont(fsStil) nameorclear() imgui.PopFont()
		imgui.Spacing()
			imgui.BeginGroup()
				if but.select_button[10] == true then
					if imgui.Button(u8"RP ������� >", imgui.ImVec2(142, 26)) then
						but.select_button[10] = false
						but.select_button[1] = true
					end
					if imgui.Button(u8"NRP ������� >", imgui.ImVec2(142, 26)) then
						but.select_button[10] = false
						but.select_button[2] = true
					end
					if imgui.Button(u8"��������� >", imgui.ImVec2(142, 26)) then
						but.select_button[10] = false
						but.select_button[3] = true
					end
				end
				if but.select_button[1] then
					if imgui.Button(u8"���������", imgui.ImVec2(142, 26)) then registerRolePlay(32) end
					if imgui.Button(u8"������� >", imgui.ImVec2(142, 26)) then 
						but.select_button[1] = false
						but.select_button[4] = true
					end
					if imgui.Button(u8"������� >", imgui.ImVec2(142, 26)) then
						but.select_button[1] = false
						but.select_button[5] = true
					end
					if imgui.Button(u8"�������� >", imgui.ImVec2(142, 26)) then
						but.select_button[1] = false
						but.select_button[6] = true
					end
					if imgui.Button(u8"������� >", imgui.ImVec2(142, 26)) then
						but.select_button[1] = false
						but.select_button[7] = true
					end
					if imgui.Button(u8"���. ����� >", imgui.ImVec2(142, 26)) then 
						but.select_button[1] = false
						but.select_button[8] = true
					end
					if imgui.Button(u8"����� ���� >", imgui.ImVec2(142, 26)) then
						but.select_button[1] = false
						but.select_button[9] = true
					end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then 
						but.select_button[1] = false 
						but.select_button[10] = true 
					end
				end
				if but.select_button[2] then
					if imgui.Button(u8"�������", imgui.ImVec2(142, 26)) then sampSendChat("/heal "..venick.p_id) end
					if imgui.Button(u8"�������", imgui.ImVec2(142, 26)) then sampSendChat("/healdisease "..venick.p_id) end
					if imgui.Button(u8"��������", imgui.ImVec2(142, 26)) then sampSendChat("/healwound "..venick.p_id) end
					if imgui.Button(u8"���. ����� >", imgui.ImVec2(142, 26)) then 
						but.select_button[2] = false
						but.select_button[11] = true
					end
					if imgui.Button(u8"����� ����", imgui.ImVec2(142, 26)) then sampSendChat("/setsex "..venick.p_id) end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then 
						but.select_button[2] = false
						but.select_button[10] = true 
					end
				end
				if but.select_button[11] then
					if imgui.Button(u8"������ ���.�����", imgui.ImVec2(142, 26)) then sampSendChat("/givemc "..venick.p_id) end
					if imgui.Button(u8"����� ���. �����", imgui.ImVec2(142, 26)) then sampSendChat("/findmc "..venick.p_id) end
					if imgui.Button(u8"�������: �����", imgui.ImVec2(142, 26)) then sampSendChat("/updatemc "..venick.p_id.." 1") end
					if imgui.Button(u8"�������: �� �����", imgui.ImVec2(142, 26)) then sampSendChat("/updatemc "..venick.p_id.." 0") end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then 
						but.select_button[11] = false
						but.select_button[2] = true
					end
				end
				if but.select_button[3] then
					CheckName()
					for k, v in pairs(rptext) do
						if k >= 35 and k <40 then
							if imgui.Button(u8(v.name), imgui.ImVec2(142, 26)) then registerRolePlay(k) end
						end
					end
					if imgui.Button(u8"������ ����", imgui.ImVec2(142, 26)) then
						started()
					end
					if imgui.Button(u8"������� ������", imgui.ImVec2(142, 26)) then
						doklad()
					end
					if imgui.Button(u8"�������� ����", imgui.ImVec2(142, 26)) then
						finished()
					end
					
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then 
						but.select_button[3] = false 
						but.select_button[10] = true 
					end
				end

				if but.select_button[4] then					
					for k, v in pairs(rptext) do
						if k >= 1 and k < 8 then
							if imgui.Button(u8(v.name), imgui.ImVec2(142, 26)) then registerRolePlay(k) end
						end
					end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then but.select_button[4] = false but.select_button[1] = true end
				end
				if but.select_button[5] then
					for k, v in pairs(rptext) do
						if k >= 8 and k < 15 then
							if imgui.Button(u8(v.name), imgui.ImVec2(142, 26)) then registerRolePlay(k) end
						end
					end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then but.select_button[5] = false but.select_button[1] = true end
				end
				if but.select_button[6] then
					for k, v in pairs(rptext) do
						if k >= 15 and k < 20 then
							if imgui.Button(u8(v.name), imgui.ImVec2(142, 26)) then registerRolePlay(k) end
						end
					end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then but.select_button[6] = false but.select_button[1] = true end
				end
				if but.select_button[7] then
					for k, v in pairs(rptext) do
						if k >= 20 and k < 24 then
							if imgui.Button(u8(v.name), imgui.ImVec2(142, 26)) then registerRolePlay(k) end
						end
					end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then but.select_button[7] = false but.select_button[1] = true end
				end
				if but.select_button[8] then
					for k, v in pairs(rptext) do
						if k >= 24 and k < 32 then
							if imgui.Button(u8(v.name), imgui.ImVec2(142, 26)) then registerRolePlay(k) end
						end
					end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then but.select_button[8] = false but.select_button[1] = true end
				end
				if but.select_button[9] then
					for k, v in pairs(rptext) do
						if k >= 33 and k < 35 then
							if imgui.Button(u8(v.name), imgui.ImVec2(142, 26)) then registerRolePlay(k) end
						end
					end
					if imgui.Button(u8"< �����", imgui.ImVec2(142, 26)) then but.select_button[9] = false but.select_button[1] = true end
				end
			imgui.EndGroup()
	imgui.End()
	imgui.PopStyleColor(5)
	imgui.PopStyleVar(2)
end

function registerRolePlay(num)
		for k, v in pairs(rptext) do
			if k == num then
				local cmdtext = v.text
				lua_thread.create(function()
					for line in cmdtext:gmatch('[^\r\n]+') do
						if line:match("{wait:%d+}") then
							wait(line:match("{wait:(%d+)}"))
						elseif line:match("{help:.+}") then
							sampAddChatMessage("[MedicalHelper] {ffffff}" ..(line:match("{help:(.+)}")), CL.COLOR_RED)
						else
							sampSendChat(tags(line))
						end
					end		
				end)
			end
		end
end

function CheckName()
	if buffer.namenumber.v == 3 and buffer.buf_nick.v == "" or buffer.namenumber.v == 0 then
		variable.sname = Name..' '..Surname
	elseif buffer.namenumber.v == 1 then variable.sname = Name
	elseif buffer.namenumber.v == 2 then variable.sname = Surname
	elseif buffer.namenumber.v == 3 then variable.sname = u8:decode(buffer.buf_nick.v)
	end
end

function nameorclear()
	if #veh_pid == 0 then
		imgui.Text('Nick Name [ID]') 
	else
		if #veh_pid == 1 then
			for k, v in pairs(veh_pid) do
				imgui.TextColoredRGB(v)
				if v:find('{.+}(.+) %[(%d+)%]') then
					venick.p_nick, venick.p_id = v:match('{.+}(.+) %[(%d+)%]')
					table.remove(veh_pid, k)
					table.insert(veh_pid, k, '{d1d1d1} > {ffffff}' ..venick.p_nick.. ' [' ..venick.p_id.. ']')
				end	
			end	
		else
			for k, v in pairs(veh_pid) do
				imgui.SameLine(16)
				imgui.TextColoredRGB(v)
				imgui.Spacing()
				if imgui.IsItemClicked() then
					for a, b in pairs(veh_pid) do
						if b:find('{.+}(.+) %[(%d+)%]') then
							venick.p_nick, venick.p_id = b:match('{.+}(.+) %[(%d+)%]')	
							table.remove(veh_pid, a)
							table.insert(veh_pid, a, '{FFFFFF}' ..venick.p_nick.. ' [' ..venick.p_id.. ']')
						end
					end
					if v:find('{.+}(.+) %[(%d+)%]') then
						venick.p_nick, venick.p_id = v:match('{.+}(.+) %[(%d+)%]')					
					end
					table.remove(veh_pid, k)
					table.insert(veh_pid, k, '{d1d1d1} > {ffffff}' ..venick.p_nick.. ' [' ..venick.p_id.. ']')
				end
			end
		end
	end
end

function checkoncar()
	for playerid = 0, 999 do
		if sampIsPlayerConnected(playerid) then
			local result, handle = sampGetCharHandleBySampPlayerId(playerid)
			if result then
				local X3, Y3, Z3 = getCharCoordinates(handle)
				local X4, Y4, Z4 = getCharCoordinates(PLAYER_PED)
				local distance = getDistanceBetweenCoords3d(X3, Y3, Z3, X4, Y4, Z4)
				local _, player_id = sampGetPlayerIdByCharHandle(playerid)
				local player_name = sampGetPlayerNickname(playerid)				
				if distance < 4 then
					if isCharInAnyCar(PLAYER_PED) then -- �������� �� ���������
						local carhandle = storeCarCharIsInNoSave(PLAYER_PED) -- ��������� handle ����������
						local idcar = getCarModel(carhandle) -- ��������� ID ����������
						if isCharInAnyCar(handle) then 
							local player_carhandle = storeCarCharIsInNoSave(handle)
							local player_idcar = getCarModel(player_carhandle) -- ��������� ID ����������
							if idcar == player_idcar then
								table.insert(veh_pid, '{FFFFFF}' ..player_name.. ' [' ..playerid.. ']')
								for k,v in pairs(skins) do
									if isCharModel(handle, v) then
										if player_name:find(".+_(.+)") then
											variable.partner = player_name:match('.+_(.+)')
										end
									end
								end
							else
								variable.partner = ""
							end
						end
					else
						table.insert(veh_pid, '{FFFFFF}' ..player_name.. ' [' ..playerid.. ']')
					end
				end
			end
		end
	end
end

--[[  function takehandle()		
	local valid, ped = getCharPlayerIsTargeting(PLAYER_HANDLE) -- �������� ����� ���������, � �������� ������� �����
	if valid and doesCharExist(ped) then -- ���� ���� ���� � �������� ����������
		local result, target_player_id = sampGetPlayerIdByCharHandle(ped) -- �������� samp-�� ������ �� ������ ���������
		local target_player_name = sampGetPlayerNickname(target_player_id)
		if result then -- ���������, ������ �� ��������� ��� �������										
			pid = target_player_id
			pnick = target_player_name
		end		
	end 
end ]]

function combo_name()
	imgui.PushItemWidth(200)
	if imgui.Combo("####3", buffer.namenumber, chgName.uname) then 
		CheckName()
		needsave() 
	end
	imgui.PopItemWidth()
end

function post()
	if imgui.Button(fa.ICON_COG.. "##1", imgui.ImVec2(21, 19)) then
		chgName.inp.v = chgName.tag[buffer.num_tag.v+1]
		chgName.inp2.v = tonumber(chgName.clist[buffer.num_tag.v+1])
		imgui.OpenPopup(u8"[Medical Helper] ��������� ����")
	end
	imgui.SameLine(99)
	imgui.PushItemWidth(190)
	if imgui.Combo("###Taglist", buffer.num_tag, chgName.tag) then
		buffer.buf_tag = tostring(chgName.tag[buffer.num_tag.v+1])
		buffer.buf_Clist = tonumber(chgName.clist[buffer.num_tag.v+1])
		sampSendChat("/clist "..buffer.buf_Clist)
		needsave() 
	end
	imgui.PopItemWidth()
	imgui.SameLine()
	ask()						
	imgui.Hint(u8'�� ������ �������� �������� ����� ���������;\n��������� ������������� ���������� ��� ���� � ������.', 0.3)
	if imgui.BeginPopupModal(u8"[Medical Helper] ��������� ����", null, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoMove) then
		imgui.Text(u8"��������� ������������� ���������� � �������� ���� � ����� ����.")
		imgui.Spacing()
		imgui.PushItemWidth(300)
			imgui.InputText(u8"##inpcastname", chgName.inp, 512, filter(1, ".+"))
		imgui.PopItemWidth()
		imgui.SameLine()
		imgui.PushItemWidth(84)
			if imgui.InputInt(u8"###smenaclist", chgName.inp2, 0, 0) then
				chgName.inp2.v = chgName.inp2.v < 0 and 0 or chgName.inp2.v > 33 and 33 or chgName.inp2.v end
		imgui.PopItemWidth()
		if imgui.Button(u8"���������", imgui.ImVec2(126,23)) then
			local exist = false
			for i,v in ipairs(chgName.tag) do
				if v == chgName.inp.v and i ~= buffer.num_tag.v+1 then
					exist = true
				end
			end
			buffer.buf_tag = chgName.inp.v--chgName.tag[num_tag.v+1]
			for i,v in ipairs(chgName.clist) do
				if v == chgName.inp2.v and i ~= buffer.num_tag.v+1 then
					exist = true
				end
			end
			if not exist then
				chgName.tag[buffer.num_tag.v+1] = chgName.inp.v
				chgName.clist[buffer.num_tag.v+1] = chgName.inp2.v
				buffer.buf_Clist = chgName.inp2.v
				imgui.CloseCurrentPopup()
			end
			needsave()
		end
		imgui.SameLine()
		if imgui.Button(u8"��������", imgui.ImVec2(128,23)) then
			chgName.tag[buffer.num_tag.v+1] = list_tag[buffer.num_tag.v+1]
			chgName.clist[buffer.num_tag.v+1] = list_clist[buffer.num_tag.v+1]
			imgui.CloseCurrentPopup()
			buffer.buf_tag = chgName.tag[buffer.num_tag.v+1]
			buffer.buf_Clist = chgName.clist[buffer.num_tag.v+1]
			needsave()
		end
		imgui.SameLine()
		if imgui.Button(u8"������", imgui.ImVec2(126,23)) then
			imgui.CloseCurrentPopup()
		end
	imgui.EndPopup()
	end
end

function window_members()
	imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 31)
	imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10, 0.10, 0.10, 1.00))
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18, 0.18, 0.18, 1.00))
	imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
		if imgui.Button(fa.ICON_REFRESH, imgui.ImVec2(21, 21)) then parseMembers() end
	imgui.PopStyleColor(3)
	imgui.PopStyleVar()
	imgui.SameLine()
	imgui.Text(u8((" ����� ������: %s"):format(#mt)))
	imgui.Spacing()
	imgui.BeginChild('##menu2_1_1', imgui.ImVec2(696, 322), false)
		imgui.Columns(5, _, true)
		imgui.SetColumnWidth(-1, 180)
			imgui.Text(u8"��� [ID]")
		imgui.NextColumn()
		imgui.SetColumnWidth(-1, 190)
			imgui.Text(u8("���������"))
		imgui.NextColumn()
		imgui.SetColumnWidth(-1, 80)
			imgui.Text(u8("������"))
		imgui.NextColumn()
		imgui.SetColumnWidth(-1, 120)
			imgui.Text(u8("���� ������"))
		imgui.NextColumn()
		imgui.SetColumnWidth(-1, 70)
			imgui.Text("AFK")
		imgui.NextColumn()
		for _, v in ipairs(mt) do
			imgui.Separator()
			imgui.SetColumnWidth(-1, 180)
				imgui.Text(u8('%s [%s]'):format(v.name, v.mid))
			imgui.NextColumn()
			imgui.SetColumnWidth(-1, 190)
				imgui.Text(('%s [%s]'):format(v.sRang, v.iRang))
			imgui.NextColumn()
			imgui.SetColumnWidth(-1, 80)
			if v.status ~= u8("�� ������") then
				imgui.TextColored(imgui.ImVec4(1.00, 0.28, 0.28, 1.00), v.status);
			else
				imgui.TextColored(imgui.ImVec4(0.70, 0.70, 0.70, 1.00), v.status);
			end
			imgui.NextColumn()
			imgui.SetColumnWidth(-1, 120)
				imgui.Text(v.invite)
			imgui.NextColumn()
			imgui.SetColumnWidth(-1, 80)
			if v.sec ~= 0 then
				if v.sec < 360 then
					imgui.Text(tostring(v.sec .. u8(' ���.')));
				else
					imgui.Text(tostring('360+' .. u8(' ���.')));
				end
			else
				imgui.Text(u8("�"));
			end
			imgui.NextColumn()
		end
		imgui.Columns(1)
	imgui.EndChild()
end

------------------------------------------------- ������� --------------------------------------------------

function cmd_vehs(arg)
	param = string.match(arg, ".+")
	if param ~= nil then
		local text = ""
		for k, v in pairs(CarList) do 
			if string.nlower(v):find(string.nlower(param):gsub('[%p%c]', '')) or string.nlower(k):find(string.nlower(param):gsub('[%p%c]', '')) then
				sampAddChatMessage("[" ..k.. "] {a6bdd7}" ..v, CL.COLOR_RED)
				text = v
			end
		end
		if #text <1 then
			sampAddChatMessage("[MedicalHelper] {a6bdd7}���������: ' ".. param .." ' �� ������.", CL.COLOR_RED)
		end
	else
		sampAddChatMessage("[MedicalHelper] {a6bdd7}�������: /vehs �������� / ID [400-611] ����������.", CL.COLOR_RED)
	end
end

-------------------------------------------- �������������� ---------------------------------------------

function calculateZone(x,y,z)
	local x,y,z = getCharCoordinates(PLAYER_PED)
    local streets = {
		{"Avispa Country Club", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
		{"Easter Bay Airport", -1315.420, -405.388, 15.406, -1264.400, -209.543, 25.406},
		{"Avispa Country Club", -2550.040, -355.493, 0.000, -2470.040, -318.493, 39.700},
		{"Easter Bay Airport", -1490.330, -209.543, 15.406, -1264.400, -148.388, 25.406},
		{"Garcia", -2395.140, -222.589, -5.3, -2354.090, -204.792, 200.000},
		{"Shady Cabin", -1632.830, -2263.440, -3.0, -1601.330, -2231.790, 200.000},
		{"East Los Santos", 2381.680, -1494.030, -89.084, 2421.030, -1454.350, 110.916},
		{"LVA Freight Depot", 1236.630, 1163.410, -89.084, 1277.050, 1203.280, 110.916},
		{"Blackfield Intersection", 1277.050, 1044.690, -89.084, 1315.350, 1087.630, 110.916},
		{"Avispa Country Club", -2470.040, -355.493, 0.000, -2270.040, -318.493, 46.100},
		{"Temple", 1252.330, -926.999, -89.084, 1357.000, -910.170, 110.916},
		{"Unity Station", 1692.620, -1971.800, -20.492, 1812.620, -1932.800, 79.508},
		{"LVA Freight Depot", 1315.350, 1044.690, -89.084, 1375.600, 1087.630, 110.916},
		{"Los Flores", 2581.730, -1454.350, -89.084, 2632.830, -1393.420, 110.916},
		{"Starfish Casino", 2437.390, 1858.100, -39.084, 2495.090, 1970.850, 60.916},
		{"Easter Bay Chemicals", -1132.820, -787.391, 0.000, -956.476, -768.027, 200.000},
		{"Downtown Los Santos", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
		{"Esplanade East", -1620.300, 1176.520, -4.5, -1580.010, 1274.260, 200.000},
		{"Market Station", 787.461, -1410.930, -34.126, 866.009, -1310.210, 65.874},
		{"Linden Station", 2811.250, 1229.590, -39.594, 2861.250, 1407.590, 60.406},
		{"Montgomery Intersection", 1582.440, 347.457, 0.000, 1664.620, 401.750, 200.000},
		{"Frederick Bridge", 2759.250, 296.501, 0.000, 2774.250, 594.757, 200.000},
		{"Yellow Bell Station", 1377.480, 2600.430, -21.926, 1492.450, 2687.360, 78.074},
		{"Downtown Los Santos", 1507.510, -1385.210, 110.916, 1582.550, -1325.310, 335.916},
		{"Jefferson", 2185.330, -1210.740, -89.084, 2281.450, -1154.590, 110.916},
		{"Mulholland", 1318.130, -910.170, -89.084, 1357.000, -768.027, 110.916},
		{"Avispa Country Club", -2361.510, -417.199, 0.000, -2270.040, -355.493, 200.000},
		{"Jefferson", 1996.910, -1449.670, -89.084, 2056.860, -1350.720, 110.916},
		{"Julius Thruway West", 1236.630, 2142.860, -89.084, 1297.470, 2243.230, 110.916},
		{"Jefferson", 2124.660, -1494.030, -89.084, 2266.210, -1449.670, 110.916},
		{"Julius Thruway North", 1848.400, 2478.490, -89.084, 1938.800, 2553.490, 110.916},
		{"Rodeo", 422.680, -1570.200, -89.084, 466.223, -1406.050, 110.916},
		{"Cranberry Station", -2007.830, 56.306, 0.000, -1922.000, 224.782, 100.000},
		{"Downtown Los Santos", 1391.050, -1026.330, -89.084, 1463.900, -926.999, 110.916},
		{"Redsands West", 1704.590, 2243.230, -89.084, 1777.390, 2342.830, 110.916},
		{"Little Mexico", 1758.900, -1722.260, -89.084, 1812.620, -1577.590, 110.916},
		{"Blackfield Intersection", 1375.600, 823.228, -89.084, 1457.390, 919.447, 110.916},
		{"Los Santos International", 1974.630, -2394.330, -39.084, 2089.000, -2256.590, 60.916},
		{"Beacon Hill", -399.633, -1075.520, -1.489, -319.033, -977.516, 198.511},
		{"Rodeo", 334.503, -1501.950, -89.084, 422.680, -1406.050, 110.916},
		{"Richman", 225.165, -1369.620, -89.084, 334.503, -1292.070, 110.916},
		{"Downtown Los Santos", 1724.760, -1250.900, -89.084, 1812.620, -1150.870, 110.916},
		{"The Strip", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
		{"Downtown Los Santos", 1378.330, -1130.850, -89.084, 1463.900, -1026.330, 110.916},
		{"Blackfield Intersection", 1197.390, 1044.690, -89.084, 1277.050, 1163.390, 110.916},
		{"Conference Center", 1073.220, -1842.270, -89.084, 1323.900, -1804.210, 110.916},
		{"Montgomery", 1451.400, 347.457, -6.1, 1582.440, 420.802, 200.000},
		{"Foster Valley", -2270.040, -430.276, -1.2, -2178.690, -324.114, 200.000},
		{"Blackfield Chapel", 1325.600, 596.349, -89.084, 1375.600, 795.010, 110.916},
		{"Los Santos International", 2051.630, -2597.260, -39.084, 2152.450, -2394.330, 60.916},
		{"Mulholland", 1096.470, -910.170, -89.084, 1169.130, -768.027, 110.916},
		{"Yellow Bell Gol Course", 1457.460, 2723.230, -89.084, 1534.560, 2863.230, 110.916},
		{"The Strip", 2027.400, 1783.230, -89.084, 2162.390, 1863.230, 110.916},
		{"Jefferson", 2056.860, -1210.740, -89.084, 2185.330, -1126.320, 110.916},
		{"Mulholland", 952.604, -937.184, -89.084, 1096.470, -860.619, 110.916},
		{"Aldea Malvada", -1372.140, 2498.520, 0.000, -1277.590, 2615.350, 200.000},
		{"Las Colinas", 2126.860, -1126.320, -89.084, 2185.330, -934.489, 110.916},
		{"Las Colinas", 1994.330, -1100.820, -89.084, 2056.860, -920.815, 110.916},
		{"Richman", 647.557, -954.662, -89.084, 768.694, -860.619, 110.916},
		{"LVA Freight Depot", 1277.050, 1087.630, -89.084, 1375.600, 1203.280, 110.916},
		{"Julius Thruway North", 1377.390, 2433.230, -89.084, 1534.560, 2507.230, 110.916},
		{"Willowfield", 2201.820, -2095.000, -89.084, 2324.000, -1989.900, 110.916},
		{"Julius Thruway North", 1704.590, 2342.830, -89.084, 1848.400, 2433.230, 110.916},
		{"Temple", 1252.330, -1130.850, -89.084, 1378.330, -1026.330, 110.916},
		{"Little Mexico", 1701.900, -1842.270, -89.084, 1812.620, -1722.260, 110.916},
		{"Queens", -2411.220, 373.539, 0.000, -2253.540, 458.411, 200.000},
		{"Las Venturas Airport", 1515.810, 1586.400, -12.500, 1729.950, 1714.560, 87.500},
		{"Richman", 225.165, -1292.070, -89.084, 466.223, -1235.070, 110.916},
		{"Temple", 1252.330, -1026.330, -89.084, 1391.050, -926.999, 110.916},
		{"East Los Santos", 2266.260, -1494.030, -89.084, 2381.680, -1372.040, 110.916},
		{"Julius Thruway East", 2623.180, 943.235, -89.084, 2749.900, 1055.960, 110.916},
		{"Willowfield", 2541.700, -1941.400, -89.084, 2703.580, -1852.870, 110.916},
		{"Las Colinas", 2056.860, -1126.320, -89.084, 2126.860, -920.815, 110.916},
		{"Julius Thruway East", 2625.160, 2202.760, -89.084, 2685.160, 2442.550, 110.916},
		{"Rodeo", 225.165, -1501.950, -89.084, 334.503, -1369.620, 110.916},
		{"Las Brujas", -365.167, 2123.010, -3.0, -208.570, 2217.680, 200.000},
		{"Julius Thruway East", 2536.430, 2442.550, -89.084, 2685.160, 2542.550, 110.916},
		{"Rodeo", 334.503, -1406.050, -89.084, 466.223, -1292.070, 110.916},
		{"Vinewood", 647.557, -1227.280, -89.084, 787.461, -1118.280, 110.916},
		{"Rodeo", 422.680, -1684.650, -89.084, 558.099, -1570.200, 110.916},
		{"Julius Thruway North", 2498.210, 2542.550, -89.084, 2685.160, 2626.550, 110.916},
		{"Downtown Los Santos", 1724.760, -1430.870, -89.084, 1812.620, -1250.900, 110.916},
		{"Rodeo", 225.165, -1684.650, -89.084, 312.803, -1501.950, 110.916},
		{"Jefferson", 2056.860, -1449.670, -89.084, 2266.210, -1372.040, 110.916},
		{"Hampton Barns", 603.035, 264.312, 0.000, 761.994, 366.572, 200.000},
		{"Temple", 1096.470, -1130.840, -89.084, 1252.330, -1026.330, 110.916},
		{"Kincaid Bridge", -1087.930, 855.370, -89.084, -961.950, 986.281, 110.916},
		{"Verona Beach", 1046.150, -1722.260, -89.084, 1161.520, -1577.590, 110.916},
		{"Commerce", 1323.900, -1722.260, -89.084, 1440.900, -1577.590, 110.916},
		{"Mulholland", 1357.000, -926.999, -89.084, 1463.900, -768.027, 110.916},
		{"Rodeo", 466.223, -1570.200, -89.084, 558.099, -1385.070, 110.916},
		{"Mulholland", 911.802, -860.619, -89.084, 1096.470, -768.027, 110.916},
		{"Mulholland", 768.694, -954.662, -89.084, 952.604, -860.619, 110.916},
		{"Julius Thruway South", 2377.390, 788.894, -89.084, 2537.390, 897.901, 110.916},
		{"Idlewood", 1812.620, -1852.870, -89.084, 1971.660, -1742.310, 110.916},
		{"Ocean Docks", 2089.000, -2394.330, -89.084, 2201.820, -2235.840, 110.916},
		{"Commerce", 1370.850, -1577.590, -89.084, 1463.900, -1384.950, 110.916},
		{"Julius Thruway North", 2121.400, 2508.230, -89.084, 2237.400, 2663.170, 110.916},
		{"Temple", 1096.470, -1026.330, -89.084, 1252.330, -910.170, 110.916},
		{"Glen Park", 1812.620, -1449.670, -89.084, 1996.910, -1350.720, 110.916},
		{"Easter Bay Airport", -1242.980, -50.096, 0.000, -1213.910, 578.396, 200.000},
		{"Martin Bridge", -222.179, 293.324, 0.000, -122.126, 476.465, 200.000},
		{"The Strip", 2106.700, 1863.230, -89.084, 2162.390, 2202.760, 110.916},
		{"Willowfield", 2541.700, -2059.230, -89.084, 2703.580, -1941.400, 110.916},
		{"Marina", 807.922, -1577.590, -89.084, 926.922, -1416.250, 110.916},
		{"Las Venturas Airport", 1457.370, 1143.210, -89.084, 1777.400, 1203.280, 110.916},
		{"Idlewood", 1812.620, -1742.310, -89.084, 1951.660, -1602.310, 110.916},
		{"Esplanade East", -1580.010, 1025.980, -6.1, -1499.890, 1274.260, 200.000},
		{"Downtown Los Santos", 1370.850, -1384.950, -89.084, 1463.900, -1170.870, 110.916},
		{"The Mako Span", 1664.620, 401.750, 0.000, 1785.140, 567.203, 200.000},
		{"Rodeo", 312.803, -1684.650, -89.084, 422.680, -1501.950, 110.916},
		{"Pershing Square", 1440.900, -1722.260, -89.084, 1583.500, -1577.590, 110.916},
		{"Mulholland", 687.802, -860.619, -89.084, 911.802, -768.027, 110.916},
		{"Gant Bridge", -2741.070, 1490.470, -6.1, -2616.400, 1659.680, 200.000},
		{"Las Colinas", 2185.330, -1154.590, -89.084, 2281.450, -934.489, 110.916},
		{"Mulholland", 1169.130, -910.170, -89.084, 1318.130, -768.027, 110.916},
		{"Julius Thruway North", 1938.800, 2508.230, -89.084, 2121.400, 2624.230, 110.916},
		{"Commerce", 1667.960, -1577.590, -89.084, 1812.620, -1430.870, 110.916},
		{"Rodeo", 72.648, -1544.170, -89.084, 225.165, -1404.970, 110.916},
		{"Roca Escalante", 2536.430, 2202.760, -89.084, 2625.160, 2442.550, 110.916},
		{"Rodeo", 72.648, -1684.650, -89.084, 225.165, -1544.170, 110.916},
		{"Market", 952.663, -1310.210, -89.084, 1072.660, -1130.850, 110.916},
		{"Las Colinas", 2632.740, -1135.040, -89.084, 2747.740, -945.035, 110.916},
		{"Mulholland", 861.085, -674.885, -89.084, 1156.550, -600.896, 110.916},
		{"King's", -2253.540, 373.539, -9.1, -1993.280, 458.411, 200.000},
		{"Redsands East", 1848.400, 2342.830, -89.084, 2011.940, 2478.490, 110.916},
		{"Downtown", -1580.010, 744.267, -6.1, -1499.890, 1025.980, 200.000},
		{"Conference Center", 1046.150, -1804.210, -89.084, 1323.900, -1722.260, 110.916},
		{"Richman", 647.557, -1118.280, -89.084, 787.461, -954.662, 110.916},
		{"Ocean Flats", -2994.490, 277.411, -9.1, -2867.850, 458.411, 200.000},
		{"Greenglass College", 964.391, 930.890, -89.084, 1166.530, 1044.690, 110.916},
		{"Glen Park", 1812.620, -1100.820, -89.084, 1994.330, -973.380, 110.916},
		{"LVA Freight Depot", 1375.600, 919.447, -89.084, 1457.370, 1203.280, 110.916},
		{"Regular Tom", -405.770, 1712.860, -3.0, -276.719, 1892.750, 200.000},
		{"Verona Beach", 1161.520, -1722.260, -89.084, 1323.900, -1577.590, 110.916},
		{"East Los Santos", 2281.450, -1372.040, -89.084, 2381.680, -1135.040, 110.916},
		{"Caligula's Palace", 2137.400, 1703.230, -89.084, 2437.390, 1783.230, 110.916},
		{"Idlewood", 1951.660, -1742.310, -89.084, 2124.660, -1602.310, 110.916},
		{"Pilgrim", 2624.400, 1383.230, -89.084, 2685.160, 1783.230, 110.916},
		{"Idlewood", 2124.660, -1742.310, -89.084, 2222.560, -1494.030, 110.916},
		{"Queens", -2533.040, 458.411, 0.000, -2329.310, 578.396, 200.000},
		{"Downtown", -1871.720, 1176.420, -4.5, -1620.300, 1274.260, 200.000},
		{"Commerce", 1583.500, -1722.260, -89.084, 1758.900, -1577.590, 110.916},
		{"East Los Santos", 2381.680, -1454.350, -89.084, 2462.130, -1135.040, 110.916},
		{"Marina", 647.712, -1577.590, -89.084, 807.922, -1416.250, 110.916},
		{"Richman", 72.648, -1404.970, -89.084, 225.165, -1235.070, 110.916},
		{"Vinewood", 647.712, -1416.250, -89.084, 787.461, -1227.280, 110.916},
		{"East Los Santos", 2222.560, -1628.530, -89.084, 2421.030, -1494.030, 110.916},
		{"Rodeo", 558.099, -1684.650, -89.084, 647.522, -1384.930, 110.916},
		{"Easter Tunnel", -1709.710, -833.034, -1.5, -1446.010, -730.118, 200.000},
		{"Rodeo", 466.223, -1385.070, -89.084, 647.522, -1235.070, 110.916},
		{"Redsands East", 1817.390, 2202.760, -89.084, 2011.940, 2342.830, 110.916},
		{"The Clown's Pocket", 2162.390, 1783.230, -89.084, 2437.390, 1883.230, 110.916},
		{"Idlewood", 1971.660, -1852.870, -89.084, 2222.560, -1742.310, 110.916},
		{"Montgomery Intersection", 1546.650, 208.164, 0.000, 1745.830, 347.457, 200.000},
		{"Willowfield", 2089.000, -2235.840, -89.084, 2201.820, -1989.900, 110.916},
		{"Temple", 952.663, -1130.840, -89.084, 1096.470, -937.184, 110.916},
		{"Prickle Pine", 1848.400, 2553.490, -89.084, 1938.800, 2863.230, 110.916},
		{"Los Santos International", 1400.970, -2669.260, -39.084, 2189.820, -2597.260, 60.916},
		{"Garver Bridge", -1213.910, 950.022, -89.084, -1087.930, 1178.930, 110.916},
		{"Garver Bridge", -1339.890, 828.129, -89.084, -1213.910, 1057.040, 110.916},
		{"Kincaid Bridge", -1339.890, 599.218, -89.084, -1213.910, 828.129, 110.916},
		{"Kincaid Bridge", -1213.910, 721.111, -89.084, -1087.930, 950.022, 110.916},
		{"Verona Beach", 930.221, -2006.780, -89.084, 1073.220, -1804.210, 110.916},
		{"Verdant Bluffs", 1073.220, -2006.780, -89.084, 1249.620, -1842.270, 110.916},
		{"Vinewood", 787.461, -1130.840, -89.084, 952.604, -954.662, 110.916},
		{"Vinewood", 787.461, -1310.210, -89.084, 952.663, -1130.840, 110.916},
		{"Commerce", 1463.900, -1577.590, -89.084, 1667.960, -1430.870, 110.916},
		{"Market", 787.461, -1416.250, -89.084, 1072.660, -1310.210, 110.916},
		{"Rockshore West", 2377.390, 596.349, -89.084, 2537.390, 788.894, 110.916},
		{"Julius Thruway North", 2237.400, 2542.550, -89.084, 2498.210, 2663.170, 110.916},
		{"East Beach", 2632.830, -1668.130, -89.084, 2747.740, -1393.420, 110.916},
		{"Fallow Bridge", 434.341, 366.572, 0.000, 603.035, 555.680, 200.000},
		{"Willowfield", 2089.000, -1989.900, -89.084, 2324.000, -1852.870, 110.916},
		{"Chinatown", -2274.170, 578.396, -7.6, -2078.670, 744.170, 200.000},
		{"El Castillo del Diablo", -208.570, 2337.180, 0.000, 8.430, 2487.180, 200.000},
		{"Ocean Docks", 2324.000, -2145.100, -89.084, 2703.580, -2059.230, 110.916},
		{"Easter Bay Chemicals", -1132.820, -768.027, 0.000, -956.476, -578.118, 200.000},
		{"The Visage", 1817.390, 1703.230, -89.084, 2027.400, 1863.230, 110.916},
		{"Ocean Flats", -2994.490, -430.276, -1.2, -2831.890, -222.589, 200.000},
		{"Richman", 321.356, -860.619, -89.084, 687.802, -768.027, 110.916},
		{"Green Palms", 176.581, 1305.450, -3.0, 338.658, 1520.720, 200.000},
		{"Richman", 321.356, -768.027, -89.084, 700.794, -674.885, 110.916},
		{"Starfish Casino", 2162.390, 1883.230, -89.084, 2437.390, 2012.180, 110.916},
		{"East Beach", 2747.740, -1668.130, -89.084, 2959.350, -1498.620, 110.916},
		{"Jefferson", 2056.860, -1372.040, -89.084, 2281.450, -1210.740, 110.916},
		{"Downtown Los Santos", 1463.900, -1290.870, -89.084, 1724.760, -1150.870, 110.916},
		{"Downtown Los Santos", 1463.900, -1430.870, -89.084, 1724.760, -1290.870, 110.916},
		{"Garver Bridge", -1499.890, 696.442, -179.615, -1339.890, 925.353, 20.385},
		{"Julius Thruway South", 1457.390, 823.228, -89.084, 2377.390, 863.229, 110.916},
		{"East Los Santos", 2421.030, -1628.530, -89.084, 2632.830, -1454.350, 110.916},
		{"Greenglass College", 964.391, 1044.690, -89.084, 1197.390, 1203.220, 110.916},
		{"Las Colinas", 2747.740, -1120.040, -89.084, 2959.350, -945.035, 110.916},
		{"Mulholland", 737.573, -768.027, -89.084, 1142.290, -674.885, 110.916},
		{"Ocean Docks", 2201.820, -2730.880, -89.084, 2324.000, -2418.330, 110.916},
		{"East Los Santos", 2462.130, -1454.350, -89.084, 2581.730, -1135.040, 110.916},
		{"Ganton", 2222.560, -1722.330, -89.084, 2632.830, -1628.530, 110.916},
		{"Avispa Country Club", -2831.890, -430.276, -6.1, -2646.400, -222.589, 200.000},
		{"Willowfield", 1970.620, -2179.250, -89.084, 2089.000, -1852.870, 110.916},
		{"Esplanade North", -1982.320, 1274.260, -4.5, -1524.240, 1358.900, 200.000},
		{"The High Roller", 1817.390, 1283.230, -89.084, 2027.390, 1469.230, 110.916},
		{"Ocean Docks", 2201.820, -2418.330, -89.084, 2324.000, -2095.000, 110.916},
		{"Last Dime Motel", 1823.080, 596.349, -89.084, 1997.220, 823.228, 110.916},
		{"Bayside Marina", -2353.170, 2275.790, 0.000, -2153.170, 2475.790, 200.000},
		{"King's", -2329.310, 458.411, -7.6, -1993.280, 578.396, 200.000},
		{"El Corona", 1692.620, -2179.250, -89.084, 1812.620, -1842.270, 110.916},
		{"Blackfield Chapel", 1375.600, 596.349, -89.084, 1558.090, 823.228, 110.916},
		{"The Pink Swan", 1817.390, 1083.230, -89.084, 2027.390, 1283.230, 110.916},
		{"Julius Thruway West", 1197.390, 1163.390, -89.084, 1236.630, 2243.230, 110.916},
		{"Los Flores", 2581.730, -1393.420, -89.084, 2747.740, -1135.040, 110.916},
		{"The Visage", 1817.390, 1863.230, -89.084, 2106.700, 2011.830, 110.916},
		{"Prickle Pine", 1938.800, 2624.230, -89.084, 2121.400, 2861.550, 110.916},
		{"Verona Beach", 851.449, -1804.210, -89.084, 1046.150, -1577.590, 110.916},
		{"Robada Intersection", -1119.010, 1178.930, -89.084, -862.025, 1351.450, 110.916},
		{"Linden Side", 2749.900, 943.235, -89.084, 2923.390, 1198.990, 110.916},
		{"Ocean Docks", 2703.580, -2302.330, -89.084, 2959.350, -2126.900, 110.916},
		{"Willowfield", 2324.000, -2059.230, -89.084, 2541.700, -1852.870, 110.916},
		{"King's", -2411.220, 265.243, -9.1, -1993.280, 373.539, 200.000},
		{"Commerce", 1323.900, -1842.270, -89.084, 1701.900, -1722.260, 110.916},
		{"Mulholland", 1269.130, -768.027, -89.084, 1414.070, -452.425, 110.916},
		{"Marina", 647.712, -1804.210, -89.084, 851.449, -1577.590, 110.916},
		{"Battery Point", -2741.070, 1268.410, -4.5, -2533.040, 1490.470, 200.000},
		{"The Four Dragons Casino", 1817.390, 863.232, -89.084, 2027.390, 1083.230, 110.916},
		{"Blackfield", 964.391, 1203.220, -89.084, 1197.390, 1403.220, 110.916},
		{"Julius Thruway North", 1534.560, 2433.230, -89.084, 1848.400, 2583.230, 110.916},
		{"Yellow Bell Gol Course", 1117.400, 2723.230, -89.084, 1457.460, 2863.230, 110.916},
		{"Idlewood", 1812.620, -1602.310, -89.084, 2124.660, -1449.670, 110.916},
		{"Redsands West", 1297.470, 2142.860, -89.084, 1777.390, 2243.230, 110.916},
		{"Doherty", -2270.040, -324.114, -1.2, -1794.920, -222.589, 200.000},
		{"Hilltop Farm", 967.383, -450.390, -3.0, 1176.780, -217.900, 200.000},
		{"Las Barrancas", -926.130, 1398.730, -3.0, -719.234, 1634.690, 200.000},
		{"Pirates in Men's Pants", 1817.390, 1469.230, -89.084, 2027.400, 1703.230, 110.916},
		{"City Hall", -2867.850, 277.411, -9.1, -2593.440, 458.411, 200.000},
		{"Avispa Country Club", -2646.400, -355.493, 0.000, -2270.040, -222.589, 200.000},
		{"The Strip", 2027.400, 863.229, -89.084, 2087.390, 1703.230, 110.916},
		{"Hashbury", -2593.440, -222.589, -1.0, -2411.220, 54.722, 200.000},
		{"Los Santos International", 1852.000, -2394.330, -89.084, 2089.000, -2179.250, 110.916},
		{"Whitewood Estates", 1098.310, 1726.220, -89.084, 1197.390, 2243.230, 110.916},
		{"Sherman Reservoir", -789.737, 1659.680, -89.084, -599.505, 1929.410, 110.916},
		{"El Corona", 1812.620, -2179.250, -89.084, 1970.620, -1852.870, 110.916},
		{"Downtown", -1700.010, 744.267, -6.1, -1580.010, 1176.520, 200.000},
		{"Foster Valley", -2178.690, -1250.970, 0.000, -1794.920, -1115.580, 200.000},
		{"Las Payasadas", -354.332, 2580.360, 2.0, -133.625, 2816.820, 200.000},
		{"Valle Ocultado", -936.668, 2611.440, 2.0, -715.961, 2847.900, 200.000},
		{"Blackfield Intersection", 1166.530, 795.010, -89.084, 1375.600, 1044.690, 110.916},
		{"Ganton", 2222.560, -1852.870, -89.084, 2632.830, -1722.330, 110.916},
		{"Easter Bay Airport", -1213.910, -730.118, 0.000, -1132.820, -50.096, 200.000},
		{"Redsands East", 1817.390, 2011.830, -89.084, 2106.700, 2202.760, 110.916},
		{"Esplanade East", -1499.890, 578.396, -79.615, -1339.890, 1274.260, 20.385},
		{"Caligula's Palace", 2087.390, 1543.230, -89.084, 2437.390, 1703.230, 110.916},
		{"Royal Casino", 2087.390, 1383.230, -89.084, 2437.390, 1543.230, 110.916},
		{"Richman", 72.648, -1235.070, -89.084, 321.356, -1008.150, 110.916},
		{"Starfish Casino", 2437.390, 1783.230, -89.084, 2685.160, 2012.180, 110.916},
		{"Mulholland", 1281.130, -452.425, -89.084, 1641.130, -290.913, 110.916},
		{"Downtown", -1982.320, 744.170, -6.1, -1871.720, 1274.260, 200.000},
		{"Hankypanky Point", 2576.920, 62.158, 0.000, 2759.250, 385.503, 200.000},
		{"K.A.C.C. Military Fuels", 2498.210, 2626.550, -89.084, 2749.900, 2861.550, 110.916},
		{"Harry Gold Parkway", 1777.390, 863.232, -89.084, 1817.390, 2342.830, 110.916},
		{"Bayside Tunnel", -2290.190, 2548.290, -89.084, -1950.190, 2723.290, 110.916},
		{"Ocean Docks", 2324.000, -2302.330, -89.084, 2703.580, -2145.100, 110.916},
		{"Richman", 321.356, -1044.070, -89.084, 647.557, -860.619, 110.916},
		{"Randolph Industrial Estate", 1558.090, 596.349, -89.084, 1823.080, 823.235, 110.916},
		{"East Beach", 2632.830, -1852.870, -89.084, 2959.350, -1668.130, 110.916},
		{"Flint Water", -314.426, -753.874, -89.084, -106.339, -463.073, 110.916},
		{"Blueberry", 19.607, -404.136, 3.8, 349.607, -220.137, 200.000},
		{"Linden Station", 2749.900, 1198.990, -89.084, 2923.390, 1548.990, 110.916},
		{"Glen Park", 1812.620, -1350.720, -89.084, 2056.860, -1100.820, 110.916},
		{"Downtown", -1993.280, 265.243, -9.1, -1794.920, 578.396, 200.000},
		{"Redsands West", 1377.390, 2243.230, -89.084, 1704.590, 2433.230, 110.916},
		{"Richman", 321.356, -1235.070, -89.084, 647.522, -1044.070, 110.916},
		{"Gant Bridge", -2741.450, 1659.680, -6.1, -2616.400, 2175.150, 200.000},
		{"Lil' Probe Inn", -90.218, 1286.850, -3.0, 153.859, 1554.120, 200.000},
		{"Flint Intersection", -187.700, -1596.760, -89.084, 17.063, -1276.600, 110.916},
		{"Las Colinas", 2281.450, -1135.040, -89.084, 2632.740, -945.035, 110.916},
		{"Sobell Rail Yards", 2749.900, 1548.990, -89.084, 2923.390, 1937.250, 110.916},
		{"The Emerald Isle", 2011.940, 2202.760, -89.084, 2237.400, 2508.230, 110.916},
		{"El Castillo del Diablo", -208.570, 2123.010, -7.6, 114.033, 2337.180, 200.000},
		{"Santa Flora", -2741.070, 458.411, -7.6, -2533.040, 793.411, 200.000},
		{"Playa del Seville", 2703.580, -2126.900, -89.084, 2959.350, -1852.870, 110.916},
		{"Market", 926.922, -1577.590, -89.084, 1370.850, -1416.250, 110.916},
		{"Queens", -2593.440, 54.722, 0.000, -2411.220, 458.411, 200.000},
		{"Pilson Intersection", 1098.390, 2243.230, -89.084, 1377.390, 2507.230, 110.916},
		{"Spinybed", 2121.400, 2663.170, -89.084, 2498.210, 2861.550, 110.916},
		{"Pilgrim", 2437.390, 1383.230, -89.084, 2624.400, 1783.230, 110.916},
		{"Blackfield", 964.391, 1403.220, -89.084, 1197.390, 1726.220, 110.916},
		{"'The Big Ear'", -410.020, 1403.340, -3.0, -137.969, 1681.230, 200.000},
		{"Dillimore", 580.794, -674.885, -9.5, 861.085, -404.790, 200.000},
		{"El Quebrados", -1645.230, 2498.520, 0.000, -1372.140, 2777.850, 200.000},
		{"Esplanade North", -2533.040, 1358.900, -4.5, -1996.660, 1501.210, 200.000},
		{"Easter Bay Airport", -1499.890, -50.096, -1.0, -1242.980, 249.904, 200.000},
		{"Fisher's Lagoon", 1916.990, -233.323, -100.000, 2131.720, 13.800, 200.000},
		{"Mulholland", 1414.070, -768.027, -89.084, 1667.610, -452.425, 110.916},
		{"East Beach", 2747.740, -1498.620, -89.084, 2959.350, -1120.040, 110.916},
		{"San Andreas Sound", 2450.390, 385.503, -100.000, 2759.250, 562.349, 200.000},
		{"Shady Creeks", -2030.120, -2174.890, -6.1, -1820.640, -1771.660, 200.000},
		{"Market", 1072.660, -1416.250, -89.084, 1370.850, -1130.850, 110.916},
		{"Rockshore West", 1997.220, 596.349, -89.084, 2377.390, 823.228, 110.916},
		{"Prickle Pine", 1534.560, 2583.230, -89.084, 1848.400, 2863.230, 110.916},
		{"Easter Basin", -1794.920, -50.096, -1.04, -1499.890, 249.904, 200.000},
		{"Leafy Hollow", -1166.970, -1856.030, 0.000, -815.624, -1602.070, 200.000},
		{"LVA Freight Depot", 1457.390, 863.229, -89.084, 1777.400, 1143.210, 110.916},
		{"Prickle Pine", 1117.400, 2507.230, -89.084, 1534.560, 2723.230, 110.916},
		{"Blueberry", 104.534, -220.137, 2.3, 349.607, 152.236, 200.000},
		{"El Castillo del Diablo", -464.515, 2217.680, 0.000, -208.570, 2580.360, 200.000},
		{"Downtown", -2078.670, 578.396, -7.6, -1499.890, 744.267, 200.000},
		{"Rockshore East", 2537.390, 676.549, -89.084, 2902.350, 943.235, 110.916},
		{"San Fierro Bay", -2616.400, 1501.210, -3.0, -1996.660, 1659.680, 200.000},
		{"Paradiso", -2741.070, 793.411, -6.1, -2533.040, 1268.410, 200.000},
		{"The Camel's Toe", 2087.390, 1203.230, -89.084, 2640.400, 1383.230, 110.916},
		{"Old Venturas Strip", 2162.390, 2012.180, -89.084, 2685.160, 2202.760, 110.916},
		{"Juniper Hill", -2533.040, 578.396, -7.6, -2274.170, 968.369, 200.000},
		{"Juniper Hollow", -2533.040, 968.369, -6.1, -2274.170, 1358.900, 200.000},
		{"Roca Escalante", 2237.400, 2202.760, -89.084, 2536.430, 2542.550, 110.916},
		{"Julius Thruway East", 2685.160, 1055.960, -89.084, 2749.900, 2626.550, 110.916},
		{"Verona Beach", 647.712, -2173.290, -89.084, 930.221, -1804.210, 110.916},
		{"Foster Valley", -2178.690, -599.884, -1.2, -1794.920, -324.114, 200.000},
		{"Arco del Oeste", -901.129, 2221.860, 0.000, -592.090, 2571.970, 200.000},
		{"Fallen Tree", -792.254, -698.555, -5.3, -452.404, -380.043, 200.000},
		{"The Farm", -1209.670, -1317.100, 114.981, -908.161, -787.391, 251.981},
		{"The Sherman Dam", -968.772, 1929.410, -3.0, -481.126, 2155.260, 200.000},
		{"Esplanade North", -1996.660, 1358.900, -4.5, -1524.240, 1592.510, 200.000},
		{"Financial", -1871.720, 744.170, -6.1, -1701.300, 1176.420, 300.000},
		{"Garcia", -2411.220, -222.589, -1.14, -2173.040, 265.243, 200.000},
		{"Montgomery", 1119.510, 119.526, -3.0, 1451.400, 493.323, 200.000},
		{"Creek", 2749.900, 1937.250, -89.084, 2921.620, 2669.790, 110.916},
		{"Los Santos International", 1249.620, -2394.330, -89.084, 1852.000, -2179.250, 110.916},
		{"Santa Maria Beach", 72.648, -2173.290, -89.084, 342.648, -1684.650, 110.916},
		{"Mulholland Intersection", 1463.900, -1150.870, -89.084, 1812.620, -768.027, 110.916},
		{"Angel Pine", -2324.940, -2584.290, -6.1, -1964.220, -2212.110, 200.000},
		{"Verdant Meadows", 37.032, 2337.180, -3.0, 435.988, 2677.900, 200.000},
		{"Octane Springs", 338.658, 1228.510, 0.000, 664.308, 1655.050, 200.000},
		{"Come-A-Lot", 2087.390, 943.235, -89.084, 2623.180, 1203.230, 110.916},
		{"Redsands West", 1236.630, 1883.110, -89.084, 1777.390, 2142.860, 110.916},
		{"Santa Maria Beach", 342.648, -2173.290, -89.084, 647.712, -1684.650, 110.916},
		{"Verdant Bluffs", 1249.620, -2179.250, -89.084, 1692.620, -1842.270, 110.916},
		{"Las Venturas Airport", 1236.630, 1203.280, -89.084, 1457.370, 1883.110, 110.916},
		{"Flint Range", -594.191, -1648.550, 0.000, -187.700, -1276.600, 200.000},
		{"Verdant Bluffs", 930.221, -2488.420, -89.084, 1249.620, -2006.780, 110.916},
		{"Palomino Creek", 2160.220, -149.004, 0.000, 2576.920, 228.322, 200.000},
		{"Ocean Docks", 2373.770, -2697.090, -89.084, 2809.220, -2330.460, 110.916},
		{"Easter Bay Airport", -1213.910, -50.096, -4.5, -947.980, 578.396, 200.000},
		{"Whitewood Estates", 883.308, 1726.220, -89.084, 1098.310, 2507.230, 110.916},
		{"Calton Heights", -2274.170, 744.170, -6.1, -1982.320, 1358.900, 200.000},
		{"Easter Basin", -1794.920, 249.904, -9.1, -1242.980, 578.396, 200.000},
		{"Los Santos Inlet", -321.744, -2224.430, -89.084, 44.615, -1724.430, 110.916},
		{"Doherty", -2173.040, -222.589, -1.0, -1794.920, 265.243, 200.000},
		{"Mount Chiliad", -2178.690, -2189.910, -47.917, -2030.120, -1771.660, 576.083},
		{"Fort Carson", -376.233, 826.326, -3.0, 123.717, 1220.440, 200.000},
		{"Foster Valley", -2178.690, -1115.580, 0.000, -1794.920, -599.884, 200.000},
		{"Ocean Flats", -2994.490, -222.589, -1.0, -2593.440, 277.411, 200.000},
		{"Fern Ridge", 508.189, -139.259, 0.000, 1306.660, 119.526, 200.000},
		{"Bayside", -2741.070, 2175.150, 0.000, -2353.170, 2722.790, 200.000},
		{"Las Venturas Airport", 1457.370, 1203.280, -89.084, 1777.390, 1883.110, 110.916},
		{"Blueberry Acres", -319.676, -220.137, 0.000, 104.534, 293.324, 200.000},
		{"Palisades", -2994.490, 458.411, -6.1, -2741.070, 1339.610, 200.000},
		{"North Rock", 2285.370, -768.027, 0.000, 2770.590, -269.740, 200.000},
		{"Hunter Quarry", 337.244, 710.840, -115.239, 860.554, 1031.710, 203.761},
		{"Los Santos International", 1382.730, -2730.880, -89.084, 2201.820, -2394.330, 110.916},
		{"Missionary Hill", -2994.490, -811.276, 0.000, -2178.690, -430.276, 200.000},
		{"San Fierro Bay", -2616.400, 1659.680, -3.0, -1996.660, 2175.150, 200.000},
		{"Restricted Area", -91.586, 1655.050, -50.000, 421.234, 2123.010, 250.000},
		{"Mount Chiliad", -2997.470, -1115.580, -47.917, -2178.690, -971.913, 576.083},
		{"Mount Chiliad", -2178.690, -1771.660, -47.917, -1936.120, -1250.970, 576.083},
		{"Easter Bay Airport", -1794.920, -730.118, -3.0, -1213.910, -50.096, 200.000},
		{"The Panopticon", -947.980, -304.320, -1.1, -319.676, 327.071, 200.000},
		{"Shady Creeks", -1820.640, -2643.680, -8.0, -1226.780, -1771.660, 200.000},
		{"Back o Beyond", -1166.970, -2641.190, 0.000, -321.744, -1856.030, 200.000},
		{"Mount Chiliad", -2994.490, -2189.910, -47.917, -2178.690, -1115.580, 576.083},
		{"Tierra Robada", -1213.910, 596.349, -242.990, -480.539, 1659.680, 900.000},
		{"Flint County", -1213.910, -2892.970, -242.990, 44.615, -768.027, 900.000},
		{"Whetstone", -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000},
		{"Bone County", -480.539, 596.349, -242.990, 869.461, 2993.870, 900.000},
		{"Tierra Robada", -2997.470, 1659.680, -242.990, -480.539, 2993.870, 900.000},
		{"San Fierro", -2997.470, -1115.580, -242.990, -1213.910, 1659.680, 900.000},
		{"Las Venturas", 869.461, 596.349, -242.990, 2997.060, 2993.870, 900.000},
		{"Red County", -1213.910, -768.027, -242.990, 2997.060, 596.349, 900.000},
		{"Los Santos", 44.615, -2892.970, -242.990, 2997.060, -768.027, 900.000}}

	local streets2 = {
        {"���� �������", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
        {"�������� �����-���", -1315.420, -405.388, 15.406, -1264.400, -209.543, 25.406},
        {"���� �������", -2550.040, -355.493, 0.000, -2470.040, -318.493, 39.700},
        {"�������� �����-���", -1490.330, -209.543, 15.406, -1264.400, -148.388, 25.406},
        {"������", -2395.140, -222.589, -5.3, -2354.090, -204.792, 200.000},
        {"�����-�����", -1632.830, -2263.440, -3.0, -1601.330, -2231.790, 200.000},
        {"��������� ���-������", 2381.680, -1494.030, -89.084, 2421.030, -1454.350, 110.916},
        {"����� ���-���������", 1236.630, 1163.410, -89.084, 1277.050, 1203.280, 110.916},
        {"����������� ��������", 1277.050, 1044.690, -89.084, 1315.350, 1087.630, 110.916},
        {"���� �������", -2470.040, -355.493, 0.000, -2270.040, -318.493, 46.100},
        {"�����", 1252.330, -926.999, -89.084, 1357.000, -910.170, 110.916},
        {"������� ������", 1692.620, -1971.800, -20.492, 1812.620, -1932.800, 79.508},
        {"����� ���-���������", 1315.350, 1044.690, -89.084, 1375.600, 1087.630, 110.916},
        {"���-������", 2581.730, -1454.350, -89.084, 2632.830, -1393.420, 110.916},
        {"������ �������� ������", 2437.390, 1858.100, -39.084, 2495.090, 1970.850, 60.916},
        {"�������� �����-���", -1132.820, -787.391, 0.000, -956.476, -768.027, 200.000},
        {"������� �����", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
        {"��������� ���������", -1620.300, 1176.520, -4.5, -1580.010, 1274.260, 200.000},
        {"������� �������", 787.461, -1410.930, -34.126, 866.009, -1310.210, 65.874},
        {"������� �������", 2811.250, 1229.590, -39.594, 2861.250, 1407.590, 60.406},
        {"����������� ����������", 1582.440, 347.457, 0.000, 1664.620, 401.750, 200.000},
        {"���� ���������", 2759.250, 296.501, 0.000, 2774.250, 594.757, 200.000},
        {"������� �������-����", 1377.480, 2600.430, -21.926, 1492.450, 2687.360, 78.074},
        {"������� �����", 1507.510, -1385.210, 110.916, 1582.550, -1325.310, 335.916},
        {"����������", 2185.330, -1210.740, -89.084, 2281.450, -1154.590, 110.916},
        {"����������", 1318.130, -910.170, -89.084, 1357.000, -768.027, 110.916},
        {"���� �������", -2361.510, -417.199, 0.000, -2270.040, -355.493, 200.000},
        {"����������", 1996.910, -1449.670, -89.084, 2056.860, -1350.720, 110.916},
        {"��������� ����� �������", 1236.630, 2142.860, -89.084, 1297.470, 2243.230, 110.916},
        {"����������", 2124.660, -1494.030, -89.084, 2266.210, -1449.670, 110.916},
        {"�������� ����� �������", 1848.400, 2478.490, -89.084, 1938.800, 2553.490, 110.916},
        {"�����", 422.680, -1570.200, -89.084, 466.223, -1406.050, 110.916},
        {"������� ����������", -2007.830, 56.306, 0.000, -1922.000, 224.782, 100.000},
        {"������� �����", 1391.050, -1026.330, -89.084, 1463.900, -926.999, 110.916},
        {"�������� ��������", 1704.590, 2243.230, -89.084, 1777.390, 2342.830, 110.916},
        {"��������� �������", 1758.900, -1722.260, -89.084, 1812.620, -1577.590, 110.916},
        {"����������� ��������", 1375.600, 823.228, -89.084, 1457.390, 919.447, 110.916},
        {"�������� ���-������", 1974.630, -2394.330, -39.084, 2089.000, -2256.590, 60.916},
        {"�����-����", -399.633, -1075.520, -1.489, -319.033, -977.516, 198.511},
        {"�����", 334.503, -1501.950, -89.084, 422.680, -1406.050, 110.916},
        {"������", 225.165, -1369.620, -89.084, 334.503, -1292.070, 110.916},
        {"������� �����", 1724.760, -1250.900, -89.084, 1812.620, -1150.870, 110.916},
        {"�����", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
        {"������� �����", 1378.330, -1130.850, -89.084, 1463.900, -1026.330, 110.916},
        {"����������� ��������", 1197.390, 1044.690, -89.084, 1277.050, 1163.390, 110.916},
        {"��������� �����", 1073.220, -1842.270, -89.084, 1323.900, -1804.210, 110.916},
        {"����������", 1451.400, 347.457, -6.1, 1582.440, 420.802, 200.000},
        {"������ ������", -2270.040, -430.276, -1.2, -2178.690, -324.114, 200.000},
        {"������� ��������", 1325.600, 596.349, -89.084, 1375.600, 795.010, 110.916},
        {"�������� ���-������", 2051.630, -2597.260, -39.084, 2152.450, -2394.330, 60.916},
        {"����������", 1096.470, -910.170, -89.084, 1169.130, -768.027, 110.916},
        {"�����-���� �������-����", 1457.460, 2723.230, -89.084, 1534.560, 2863.230, 110.916},
        {"�����", 2027.400, 1783.230, -89.084, 2162.390, 1863.230, 110.916},
        {"����������", 2056.860, -1210.740, -89.084, 2185.330, -1126.320, 110.916},
        {"����������", 952.604, -937.184, -89.084, 1096.470, -860.619, 110.916},
        {"������-��������", -1372.140, 2498.520, 0.000, -1277.590, 2615.350, 200.000},
        {"���-�������", 2126.860, -1126.320, -89.084, 2185.330, -934.489, 110.916},
        {"���-�������", 1994.330, -1100.820, -89.084, 2056.860, -920.815, 110.916},
        {"������", 647.557, -954.662, -89.084, 768.694, -860.619, 110.916},
        {"����� ���-���������", 1277.050, 1087.630, -89.084, 1375.600, 1203.280, 110.916},
        {"�������� ����� �������", 1377.390, 2433.230, -89.084, 1534.560, 2507.230, 110.916},
        {"����������", 2201.820, -2095.000, -89.084, 2324.000, -1989.900, 110.916},
        {"�������� ����� �������", 1704.590, 2342.830, -89.084, 1848.400, 2433.230, 110.916},
        {"�����", 1252.330, -1130.850, -89.084, 1378.330, -1026.330, 110.916},
        {"��������� �������", 1701.900, -1842.270, -89.084, 1812.620, -1722.260, 110.916},
        {"�����", -2411.220, 373.539, 0.000, -2253.540, 458.411, 200.000},
        {"�������� ���-��������", 1515.810, 1586.400, -12.500, 1729.950, 1714.560, 87.500},
        {"������", 225.165, -1292.070, -89.084, 466.223, -1235.070, 110.916},
        {"�����", 1252.330, -1026.330, -89.084, 1391.050, -926.999, 110.916},
        {"��������� ���-������", 2266.260, -1494.030, -89.084, 2381.680, -1372.040, 110.916},
        {"��������� ����� �������", 2623.180, 943.235, -89.084, 2749.900, 1055.960, 110.916},
        {"����������", 2541.700, -1941.400, -89.084, 2703.580, -1852.870, 110.916},
        {"���-�������", 2056.860, -1126.320, -89.084, 2126.860, -920.815, 110.916},
        {"��������� ����� �������", 2625.160, 2202.760, -89.084, 2685.160, 2442.550, 110.916},
        {"�����", 225.165, -1501.950, -89.084, 334.503, -1369.620, 110.916},
        {"���-������", -365.167, 2123.010, -3.0, -208.570, 2217.680, 200.000},
        {"��������� ����� �������", 2536.430, 2442.550, -89.084, 2685.160, 2542.550, 110.916},
        {"�����", 334.503, -1406.050, -89.084, 466.223, -1292.070, 110.916},
        {"�������", 647.557, -1227.280, -89.084, 787.461, -1118.280, 110.916},
        {"�����", 422.680, -1684.650, -89.084, 558.099, -1570.200, 110.916},
        {"�������� ����� �������", 2498.210, 2542.550, -89.084, 2685.160, 2626.550, 110.916},
        {"������� �����", 1724.760, -1430.870, -89.084, 1812.620, -1250.900, 110.916},
        {"�����", 225.165, -1684.650, -89.084, 312.803, -1501.950, 110.916},
        {"����������", 2056.860, -1449.670, -89.084, 2266.210, -1372.040, 110.916},
        {"�������-�����", 603.035, 264.312, 0.000, 761.994, 366.572, 200.000},
        {"�����", 1096.470, -1130.840, -89.084, 1252.330, -1026.330, 110.916},
        {"���� ��������", -1087.930, 855.370, -89.084, -961.950, 986.281, 110.916},
        {"���� �������", 1046.150, -1722.260, -89.084, 1161.520, -1577.590, 110.916},
        {"������������ �����", 1323.900, -1722.260, -89.084, 1440.900, -1577.590, 110.916},
        {"����������", 1357.000, -926.999, -89.084, 1463.900, -768.027, 110.916},
        {"�����", 466.223, -1570.200, -89.084, 558.099, -1385.070, 110.916},
        {"����������", 911.802, -860.619, -89.084, 1096.470, -768.027, 110.916},
        {"����������", 768.694, -954.662, -89.084, 952.604, -860.619, 110.916},
        {"����� ����� �������", 2377.390, 788.894, -89.084, 2537.390, 897.901, 110.916},
        {"�������", 1812.620, -1852.870, -89.084, 1971.660, -1742.310, 110.916},
        {"��������� ����", 2089.000, -2394.330, -89.084, 2201.820, -2235.840, 110.916},
        {"������������ �����", 1370.850, -1577.590, -89.084, 1463.900, -1384.950, 110.916},
        {"�������� ����� �������", 2121.400, 2508.230, -89.084, 2237.400, 2663.170, 110.916},
        {"�����", 1096.470, -1026.330, -89.084, 1252.330, -910.170, 110.916},
        {"���� ����", 1812.620, -1449.670, -89.084, 1996.910, -1350.720, 110.916},
        {"�������� �����-���", -1242.980, -50.096, 0.000, -1213.910, 578.396, 200.000},
        {"���� �������", -222.179, 293.324, 0.000, -122.126, 476.465, 200.000},
        {"�����", 2106.700, 1863.230, -89.084, 2162.390, 2202.760, 110.916},
        {"����������", 2541.700, -2059.230, -89.084, 2703.580, -1941.400, 110.916},
        {"������", 807.922, -1577.590, -89.084, 926.922, -1416.250, 110.916},
        {"�������� ���-��������", 1457.370, 1143.210, -89.084, 1777.400, 1203.280, 110.916},
        {"�������", 1812.620, -1742.310, -89.084, 1951.660, -1602.310, 110.916},
        {"��������� ���������", -1580.010, 1025.980, -6.1, -1499.890, 1274.260, 200.000},
        {"������� �����", 1370.850, -1384.950, -89.084, 1463.900, -1170.870, 110.916},
        {"���� �����", 1664.620, 401.750, 0.000, 1785.140, 567.203, 200.000},
        {"�����", 312.803, -1684.650, -89.084, 422.680, -1501.950, 110.916},
        {"������� ��������", 1440.900, -1722.260, -89.084, 1583.500, -1577.590, 110.916},
        {"����������", 687.802, -860.619, -89.084, 911.802, -768.027, 110.916},
        {"���� �����", -2741.070, 1490.470, -6.1, -2616.400, 1659.680, 200.000},
        {"���-�������", 2185.330, -1154.590, -89.084, 2281.450, -934.489, 110.916},
        {"����������", 1169.130, -910.170, -89.084, 1318.130, -768.027, 110.916},
        {"�������� ����� �������", 1938.800, 2508.230, -89.084, 2121.400, 2624.230, 110.916},
        {"������������ �����", 1667.960, -1577.590, -89.084, 1812.620, -1430.870, 110.916},
        {"�����", 72.648, -1544.170, -89.084, 225.165, -1404.970, 110.916},
        {"����-���������", 2536.430, 2202.760, -89.084, 2625.160, 2442.550, 110.916},
        {"�����", 72.648, -1684.650, -89.084, 225.165, -1544.170, 110.916},
        {"������", 952.663, -1310.210, -89.084, 1072.660, -1130.850, 110.916},
        {"���-�������", 2632.740, -1135.040, -89.084, 2747.740, -945.035, 110.916},
        {"����������", 861.085, -674.885, -89.084, 1156.550, -600.896, 110.916},
        {"�����", -2253.540, 373.539, -9.1, -1993.280, 458.411, 200.000},
        {"��������� ��������", 1848.400, 2342.830, -89.084, 2011.940, 2478.490, 110.916},
        {"������� �����", -1580.010, 744.267, -6.1, -1499.890, 1025.980, 200.000},
        {"��������� �����", 1046.150, -1804.210, -89.084, 1323.900, -1722.260, 110.916},
        {"������", 647.557, -1118.280, -89.084, 787.461, -954.662, 110.916},
        {"�����-�����", -2994.490, 277.411, -9.1, -2867.850, 458.411, 200.000},
        {"������� ���������", 964.391, 930.890, -89.084, 1166.530, 1044.690, 110.916},
        {"���� ����", 1812.620, -1100.820, -89.084, 1994.330, -973.380, 110.916},
        {"����� ���-���������", 1375.600, 919.447, -89.084, 1457.370, 1203.280, 110.916},
        {"��������-���", -405.770, 1712.860, -3.0, -276.719, 1892.750, 200.000},
        {"���� �������", 1161.520, -1722.260, -89.084, 1323.900, -1577.590, 110.916},
        {"��������� ���-������", 2281.450, -1372.040, -89.084, 2381.680, -1135.040, 110.916},
        {"������ ��������", 2137.400, 1703.230, -89.084, 2437.390, 1783.230, 110.916},
        {"�������", 1951.660, -1742.310, -89.084, 2124.660, -1602.310, 110.916},
        {"��������", 2624.400, 1383.230, -89.084, 2685.160, 1783.230, 110.916},
        {"�������", 2124.660, -1742.310, -89.084, 2222.560, -1494.030, 110.916},
        {"�����", -2533.040, 458.411, 0.000, -2329.310, 578.396, 200.000},
        {"������� �����", -1871.720, 1176.420, -4.5, -1620.300, 1274.260, 200.000},
        {"������������ �����", 1583.500, -1722.260, -89.084, 1758.900, -1577.590, 110.916},
        {"��������� ���-������", 2381.680, -1454.350, -89.084, 2462.130, -1135.040, 110.916},
        {"������", 647.712, -1577.590, -89.084, 807.922, -1416.250, 110.916},
        {"������", 72.648, -1404.970, -89.084, 225.165, -1235.070, 110.916},
        {"�������", 647.712, -1416.250, -89.084, 787.461, -1227.280, 110.916},
        {"��������� ���-������", 2222.560, -1628.530, -89.084, 2421.030, -1494.030, 110.916},
        {"�����", 558.099, -1684.650, -89.084, 647.522, -1384.930, 110.916},
        {"��������� �������", -1709.710, -833.034, -1.5, -1446.010, -730.118, 200.000},
        {"�����", 466.223, -1385.070, -89.084, 647.522, -1235.070, 110.916},
        {"��������� ��������", 1817.390, 2202.760, -89.084, 2011.940, 2342.830, 110.916},
        {"������ ������� ������", 2162.390, 1783.230, -89.084, 2437.390, 1883.230, 110.916},
        {"�������", 1971.660, -1852.870, -89.084, 2222.560, -1742.310, 110.916},
        {"����������� ����������", 1546.650, 208.164, 0.000, 1745.830, 347.457, 200.000},
        {"����������", 2089.000, -2235.840, -89.084, 2201.820, -1989.900, 110.916},
        {"�����", 952.663, -1130.840, -89.084, 1096.470, -937.184, 110.916},
        {"�����-����", 1848.400, 2553.490, -89.084, 1938.800, 2863.230, 110.916},
        {"�������� ���-������", 1400.970, -2669.260, -39.084, 2189.820, -2597.260, 60.916},
        {"���� �������", -1213.910, 950.022, -89.084, -1087.930, 1178.930, 110.916},
        {"���� �������", -1339.890, 828.129, -89.084, -1213.910, 1057.040, 110.916},
        {"���� ��������", -1339.890, 599.218, -89.084, -1213.910, 828.129, 110.916},
        {"���� ��������", -1213.910, 721.111, -89.084, -1087.930, 950.022, 110.916},
        {"���� �������", 930.221, -2006.780, -89.084, 1073.220, -1804.210, 110.916},
        {"������������", 1073.220, -2006.780, -89.084, 1249.620, -1842.270, 110.916},
        {"�������", 787.461, -1130.840, -89.084, 952.604, -954.662, 110.916},
        {"�������", 787.461, -1310.210, -89.084, 952.663, -1130.840, 110.916},
        {"������������ �����", 1463.900, -1577.590, -89.084, 1667.960, -1430.870, 110.916},
        {"������", 787.461, -1416.250, -89.084, 1072.660, -1310.210, 110.916},
        {"�������� ������", 2377.390, 596.349, -89.084, 2537.390, 788.894, 110.916},
        {"�������� ����� �������", 2237.400, 2542.550, -89.084, 2498.210, 2663.170, 110.916},
        {"��������� ����", 2632.830, -1668.130, -89.084, 2747.740, -1393.420, 110.916},
        {"���� �������", 434.341, 366.572, 0.000, 603.035, 555.680, 200.000},
        {"����������", 2089.000, -1989.900, -89.084, 2324.000, -1852.870, 110.916},
        {"���������", -2274.170, 578.396, -7.6, -2078.670, 744.170, 200.000},
        {"���-��������-����-������", -208.570, 2337.180, 0.000, 8.430, 2487.180, 200.000},
        {"��������� ����", 2324.000, -2145.100, -89.084, 2703.580, -2059.230, 110.916},
        {"�������� �����-���", -1132.820, -768.027, 0.000, -956.476, -578.118, 200.000},
        {"������ ������", 1817.390, 1703.230, -89.084, 2027.400, 1863.230, 110.916},
        {"�����-�����", -2994.490, -430.276, -1.2, -2831.890, -222.589, 200.000},
        {"������", 321.356, -860.619, -89.084, 687.802, -768.027, 110.916},
        {"�������� ��������", 176.581, 1305.450, -3.0, 338.658, 1520.720, 200.000},
        {"������", 321.356, -768.027, -89.084, 700.794, -674.885, 110.916},
        {"������ �������� ������", 2162.390, 1883.230, -89.084, 2437.390, 2012.180, 110.916},
        {"��������� ����", 2747.740, -1668.130, -89.084, 2959.350, -1498.620, 110.916},
        {"����������", 2056.860, -1372.040, -89.084, 2281.450, -1210.740, 110.916},
        {"������� �����", 1463.900, -1290.870, -89.084, 1724.760, -1150.870, 110.916},
        {"������� �����", 1463.900, -1430.870, -89.084, 1724.760, -1290.870, 110.916},
        {"���� �������", -1499.890, 696.442, -179.615, -1339.890, 925.353, 20.385},
        {"����� ����� �������", 1457.390, 823.228, -89.084, 2377.390, 863.229, 110.916},
        {"��������� ���-������", 2421.030, -1628.530, -89.084, 2632.830, -1454.350, 110.916},
        {"������� ����������", 964.391, 1044.690, -89.084, 1197.390, 1203.220, 110.916},
        {"���-�������", 2747.740, -1120.040, -89.084, 2959.350, -945.035, 110.916},
        {"����������", 737.573, -768.027, -89.084, 1142.290, -674.885, 110.916},
        {"��������� ����", 2201.820, -2730.880, -89.084, 2324.000, -2418.330, 110.916},
        {"��������� ���-������", 2462.130, -1454.350, -89.084, 2581.730, -1135.040, 110.916},
        {"������", 2222.560, -1722.330, -89.084, 2632.830, -1628.530, 110.916},
        {"���� �������", -2831.890, -430.276, -6.1, -2646.400, -222.589, 200.000},
        {"����������", 1970.620, -2179.250, -89.084, 2089.000, -1852.870, 110.916},
        {"�������� ���������", -1982.320, 1274.260, -4.5, -1524.240, 1358.900, 200.000},
        {"������ ����-������", 1817.390, 1283.230, -89.084, 2027.390, 1469.230, 110.916},
        {"��������� ����", 2201.820, -2418.330, -89.084, 2324.000, -2095.000, 110.916},
        {"������ ���������� ����", 1823.080, 596.349, -89.084, 1997.220, 823.228, 110.916},
        {"��������-������", -2353.170, 2275.790, 0.000, -2153.170, 2475.790, 200.000},
        {"�����", -2329.310, 458.411, -7.6, -1993.280, 578.396, 200.000},
        {"���-������", 1692.620, -2179.250, -89.084, 1812.620, -1842.270, 110.916},
        {"������� ��������", 1375.600, 596.349, -89.084, 1558.090, 823.228, 110.916},
        {"�������� �������", 1817.390, 1083.230, -89.084, 2027.390, 1283.230, 110.916},
        {"��������� ����� �������", 1197.390, 1163.390, -89.084, 1236.630, 2243.230, 110.916},
        {"���-������", 2581.730, -1393.420, -89.084, 2747.740, -1135.040, 110.916},
        {"������ ������", 1817.390, 1863.230, -89.084, 2106.700, 2011.830, 110.916},
        {"�����-����", 1938.800, 2624.230, -89.084, 2121.400, 2861.550, 110.916},
        {"���� �������", 851.449, -1804.210, -89.084, 1046.150, -1577.590, 110.916},
        {"����������� ������", -1119.010, 1178.930, -89.084, -862.025, 1351.450, 110.916},
        {"������-����", 2749.900, 943.235, -89.084, 2923.390, 1198.990, 110.916},
        {"��������� ����", 2703.580, -2302.330, -89.084, 2959.350, -2126.900, 110.916},
        {"����������", 2324.000, -2059.230, -89.084, 2541.700, -1852.870, 110.916},
        {"�����", -2411.220, 265.243, -9.1, -1993.280, 373.539, 200.000},
        {"������������ �����", 1323.900, -1842.270, -89.084, 1701.900, -1722.260, 110.916},
        {"����������", 1269.130, -768.027, -89.084, 1414.070, -452.425, 110.916},
        {"������", 647.712, -1804.210, -89.084, 851.449, -1577.590, 110.916},
        {"�������-�����", -2741.070, 1268.410, -4.5, -2533.040, 1490.470, 200.000},
        {"������ �4 �������", 1817.390, 863.232, -89.084, 2027.390, 1083.230, 110.916},
        {"��������", 964.391, 1203.220, -89.084, 1197.390, 1403.220, 110.916},
        {"�������� ����� �������", 1534.560, 2433.230, -89.084, 1848.400, 2583.230, 110.916},
        {"�����-���� �������-����", 1117.400, 2723.230, -89.084, 1457.460, 2863.230, 110.916},
        {"�������", 1812.620, -1602.310, -89.084, 2124.660, -1449.670, 110.916},
        {"�������� ��������", 1297.470, 2142.860, -89.084, 1777.390, 2243.230, 110.916},
        {"������", -2270.040, -324.114, -1.2, -1794.920, -222.589, 200.000},
        {"����� �������", 967.383, -450.390, -3.0, 1176.780, -217.900, 200.000},
        {"���-���������", -926.130, 1398.730, -3.0, -719.234, 1634.690, 200.000},
        {"������ �PIMP�", 1817.390, 1469.230, -89.084, 2027.400, 1703.230, 110.916},
        {"���� ����", -2867.850, 277.411, -9.1, -2593.440, 458.411, 200.000},
        {"���� �������", -2646.400, -355.493, 0.000, -2270.040, -222.589, 200.000},
        {"�����", 2027.400, 863.229, -89.084, 2087.390, 1703.230, 110.916},
        {"�������", -2593.440, -222.589, -1.0, -2411.220, 54.722, 200.000},
        {"�������� ���-������", 1852.000, -2394.330, -89.084, 2089.000, -2179.250, 110.916},
        {"�������-�������", 1098.310, 1726.220, -89.084, 1197.390, 2243.230, 110.916},
        {"������������� �������", -789.737, 1659.680, -89.084, -599.505, 1929.410, 110.916},
        {"���-������", 1812.620, -2179.250, -89.084, 1970.620, -1852.870, 110.916},
        {"������� �����", -1700.010, 744.267, -6.1, -1580.010, 1176.520, 200.000},
        {"������ ������", -2178.690, -1250.970, 0.000, -1794.920, -1115.580, 200.000},
        {"���-��������", -354.332, 2580.360, 2.0, -133.625, 2816.820, 200.000},
        {"������ ���������", -936.668, 2611.440, 2.0, -715.961, 2847.900, 200.000},
        {"����������� ��������", 1166.530, 795.010, -89.084, 1375.600, 1044.690, 110.916},
        {"������", 2222.560, -1852.870, -89.084, 2632.830, -1722.330, 110.916},
        {"�������� �����-���", -1213.910, -730.118, 0.000, -1132.820, -50.096, 200.000},
        {"��������� ��������", 1817.390, 2011.830, -89.084, 2106.700, 2202.760, 110.916},
        {"��������� ���������", -1499.890, 578.396, -79.615, -1339.890, 1274.260, 20.385},
        {"������ ��������", 2087.390, 1543.230, -89.084, 2437.390, 1703.230, 110.916},
        {"������ �������", 2087.390, 1383.230, -89.084, 2437.390, 1543.230, 110.916},
        {"������", 72.648, -1235.070, -89.084, 321.356, -1008.150, 110.916},
        {"������ �������� ������", 2437.390, 1783.230, -89.084, 2685.160, 2012.180, 110.916},
        {"����������", 1281.130, -452.425, -89.084, 1641.130, -290.913, 110.916},
        {"������� �����", -1982.320, 744.170, -6.1, -1871.720, 1274.260, 200.000},
        {"�����-�����-�����", 2576.920, 62.158, 0.000, 2759.250, 385.503, 200.000},
        {"�.�.�.�.", 2498.210, 2626.550, -89.084, 2749.900, 2861.550, 110.916},
        {"���������� ������-����", 1777.390, 863.232, -89.084, 1817.390, 2342.830, 110.916},
        {"������� �������", -2290.190, 2548.290, -89.084, -1950.190, 2723.290, 110.916},
        {"��������� ����", 2324.000, -2302.330, -89.084, 2703.580, -2145.100, 110.916},
        {"������", 321.356, -1044.070, -89.084, 647.557, -860.619, 110.916},
        {"����� ����� ���������", 1558.090, 596.349, -89.084, 1823.080, 823.235, 110.916},
        {"��������� ����", 2632.830, -1852.870, -89.084, 2959.350, -1668.130, 110.916},
        {"�����-�����", -314.426, -753.874, -89.084, -106.339, -463.073, 110.916},
        {"��������", 19.607, -404.136, 3.8, 349.607, -220.137, 200.000},
        {"������� �������", 2749.900, 1198.990, -89.084, 2923.390, 1548.990, 110.916},
        {"���� ����", 1812.620, -1350.720, -89.084, 2056.860, -1100.820, 110.916},
        {"������� �����", -1993.280, 265.243, -9.1, -1794.920, 578.396, 200.000},
        {"�������� ��������", 1377.390, 2243.230, -89.084, 1704.590, 2433.230, 110.916},
        {"������", 321.356, -1235.070, -89.084, 647.522, -1044.070, 110.916},
        {"���� �����", -2741.450, 1659.680, -6.1, -2616.400, 2175.150, 200.000},
        {"��� �Probe Inn�", -90.218, 1286.850, -3.0, 153.859, 1554.120, 200.000},
        {"����������� �����", -187.700, -1596.760, -89.084, 17.063, -1276.600, 110.916},
        {"���-�������", 2281.450, -1135.040, -89.084, 2632.740, -945.035, 110.916},
        {"������-����-����", 2749.900, 1548.990, -89.084, 2923.390, 1937.250, 110.916},
        {"���������� ������", 2011.940, 2202.760, -89.084, 2237.400, 2508.230, 110.916},
        {"���-��������-����-������", -208.570, 2123.010, -7.6, 114.033, 2337.180, 200.000},
        {"�����-�����", -2741.070, 458.411, -7.6, -2533.040, 793.411, 200.000},
        {"�����-����-������", 2703.580, -2126.900, -89.084, 2959.350, -1852.870, 110.916},
        {"������", 926.922, -1577.590, -89.084, 1370.850, -1416.250, 110.916},
        {"�����", -2593.440, 54.722, 0.000, -2411.220, 458.411, 200.000},
        {"����������� ������", 1098.390, 2243.230, -89.084, 1377.390, 2507.230, 110.916},
        {"��������", 2121.400, 2663.170, -89.084, 2498.210, 2861.550, 110.916},
        {"��������", 2437.390, 1383.230, -89.084, 2624.400, 1783.230, 110.916},
        {"��������", 964.391, 1403.220, -89.084, 1197.390, 1726.220, 110.916},
        {"�������� ���", -410.020, 1403.340, -3.0, -137.969, 1681.230, 200.000},
        {"��������", 580.794, -674.885, -9.5, 861.085, -404.790, 200.000},
        {"���-��������", -1645.230, 2498.520, 0.000, -1372.140, 2777.850, 200.000},
        {"�������� ���������", -2533.040, 1358.900, -4.5, -1996.660, 1501.210, 200.000},
        {"�������� �����-���", -1499.890, -50.096, -1.0, -1242.980, 249.904, 200.000},
        {"�������� ������", 1916.990, -233.323, -100.000, 2131.720, 13.800, 200.000},
        {"����������", 1414.070, -768.027, -89.084, 1667.610, -452.425, 110.916},
        {"��������� ����", 2747.740, -1498.620, -89.084, 2959.350, -1120.040, 110.916},
        {"���-������� �����", 2450.390, 385.503, -100.000, 2759.250, 562.349, 200.000},
        {"�������� �����", -2030.120, -2174.890, -6.1, -1820.640, -1771.660, 200.000},
        {"������", 1072.660, -1416.250, -89.084, 1370.850, -1130.850, 110.916},
        {"�������� ������", 1997.220, 596.349, -89.084, 2377.390, 823.228, 110.916},
        {"�����-����", 1534.560, 2583.230, -89.084, 1848.400, 2863.230, 110.916},
        {"������ �����", -1794.920, -50.096, -1.04, -1499.890, 249.904, 200.000},
        {"����-������", -1166.970, -1856.030, 0.000, -815.624, -1602.070, 200.000},
        {"����� ���-���������", 1457.390, 863.229, -89.084, 1777.400, 1143.210, 110.916},
        {"�����-����", 1117.400, 2507.230, -89.084, 1534.560, 2723.230, 110.916},
        {"��������", 104.534, -220.137, 2.3, 349.607, 152.236, 200.000},
        {"���-��������-����-������", -464.515, 2217.680, 0.000, -208.570, 2580.360, 200.000},
        {"������� �����", -2078.670, 578.396, -7.6, -1499.890, 744.267, 200.000},
        {"��������� ������", 2537.390, 676.549, -89.084, 2902.350, 943.235, 110.916},
        {"����� ���-������", -2616.400, 1501.210, -3.0, -1996.660, 1659.680, 200.000},
        {"��������", -2741.070, 793.411, -6.1, -2533.040, 1268.410, 200.000},
        {"������ ������ ��������", 2087.390, 1203.230, -89.084, 2640.400, 1383.230, 110.916},
        {"���-��������-�����", 2162.390, 2012.180, -89.084, 2685.160, 2202.760, 110.916},
        {"��������-����", -2533.040, 578.396, -7.6, -2274.170, 968.369, 200.000},
        {"��������-������", -2533.040, 968.369, -6.1, -2274.170, 1358.900, 200.000},
        {"����-���������", 2237.400, 2202.760, -89.084, 2536.430, 2542.550, 110.916},
        {"��������� ����� �������", 2685.160, 1055.960, -89.084, 2749.900, 2626.550, 110.916},
        {"���� �������", 647.712, -2173.290, -89.084, 930.221, -1804.210, 110.916},
        {"������ ������", -2178.690, -599.884, -1.2, -1794.920, -324.114, 200.000},
        {"����-����-�����", -901.129, 2221.860, 0.000, -592.090, 2571.970, 200.000},
        {"�������� ������", -792.254, -698.555, -5.3, -452.404, -380.043, 200.000},
        {"�����", -1209.670, -1317.100, 114.981, -908.161, -787.391, 251.981},
        {"����� �������", -968.772, 1929.410, -3.0, -481.126, 2155.260, 200.000},
        {"�������� ���������", -1996.660, 1358.900, -4.5, -1524.240, 1592.510, 200.000},
        {"���������� �����", -1871.720, 744.170, -6.1, -1701.300, 1176.420, 300.000},
        {"������", -2411.220, -222.589, -1.14, -2173.040, 265.243, 200.000},
        {"����������", 1119.510, 119.526, -3.0, 1451.400, 493.323, 200.000},
        {"����", 2749.900, 1937.250, -89.084, 2921.620, 2669.790, 110.916},
        {"�������� ���-������", 1249.620, -2394.330, -89.084, 1852.000, -2179.250, 110.916},
        {"���� ������-������", 72.648, -2173.290, -89.084, 342.648, -1684.650, 110.916},
        {"����������� ����������", 1463.900, -1150.870, -89.084, 1812.620, -768.027, 110.916},
        {"�������-����", -2324.940, -2584.290, -6.1, -1964.220, -2212.110, 200.000},
        {"¸�����-������", 37.032, 2337.180, -3.0, 435.988, 2677.900, 200.000},
        {"�����-�������", 338.658, 1228.510, 0.000, 664.308, 1655.050, 200.000},
        {"������ ���-�-���", 2087.390, 943.235, -89.084, 2623.180, 1203.230, 110.916},
        {"�������� ��������", 1236.630, 1883.110, -89.084, 1777.390, 2142.860, 110.916},
        {"���� ������-������", 342.648, -2173.290, -89.084, 647.712, -1684.650, 110.916},
        {"������������", 1249.620, -2179.250, -89.084, 1692.620, -1842.270, 110.916},
        {"�������� ���-��������", 1236.630, 1203.280, -89.084, 1457.370, 1883.110, 110.916},
        {"����� �����", -594.191, -1648.550, 0.000, -187.700, -1276.600, 200.000},
        {"������������", 930.221, -2488.420, -89.084, 1249.620, -2006.780, 110.916},
        {"�������� ����", 2160.220, -149.004, 0.000, 2576.920, 228.322, 200.000},
        {"��������� ����", 2373.770, -2697.090, -89.084, 2809.220, -2330.460, 110.916},
        {"�������� �����-���", -1213.910, -50.096, -4.5, -947.980, 578.396, 200.000},
        {"�������-�������", 883.308, 1726.220, -89.084, 1098.310, 2507.230, 110.916},
        {"������-�����", -2274.170, 744.170, -6.1, -1982.320, 1358.900, 200.000},
        {"������ �����", -1794.920, 249.904, -9.1, -1242.980, 578.396, 200.000}, 
        {"����� ���-������", -321.744, -2224.430, -89.084, 44.615, -1724.430, 110.916},
        {"������", -2173.040, -222.589, -1.0, -1794.920, 265.243, 200.000},
        {"���� ������", -2178.690, -2189.910, -47.917, -2030.120, -1771.660, 576.083},
        {"����-������", -376.233, 826.326, -3.0, 123.717, 1220.440, 200.000},
        {"������ ������", -2178.690, -1115.580, 0.000, -1794.920, -599.884, 200.000},
        {"�����-�����", -2994.490, -222.589, -1.0, -2593.440, 277.411, 200.000},
        {"����-����", 508.189, -139.259, 0.000, 1306.660, 119.526, 200.000},
        {"�������", -2741.070, 2175.150, 0.000, -2353.170, 2722.790, 200.000},
        {"�������� ���-��������", 1457.370, 1203.280, -89.084, 1777.390, 1883.110, 110.916},
        {"�������� ��������", -319.676, -220.137, 0.000, 104.534, 293.324, 200.000},
        {"���������", -2994.490, 458.411, -6.1, -2741.070, 1339.610, 200.000},
        {"����-���", 2285.370, -768.027, 0.000, 2770.590, -269.740, 200.000},
        {"������ �������", 337.244, 710.840, -115.239, 860.554, 1031.710, 203.761},
        {"�������� ���-������", 1382.730, -2730.880, -89.084, 2201.820, -2394.330, 110.916},
        {"���������-����", -2994.490, -811.276, 0.000, -2178.690, -430.276, 200.000},
        {"����� ���-������", -2616.400, 1659.680, -3.0, -1996.660, 2175.150, 200.000},
        {"��������� ����", -91.586, 1655.050, -50.000, 421.234, 2123.010, 250.000},
        {"���� �������", -2997.470, -1115.580, -47.917, -2178.690, -971.913, 576.083},
        {"���� �������", -2178.690, -1771.660, -47.917, -1936.120, -1250.970, 576.083},
        {"�������� �����-���", -1794.920, -730.118, -3.0, -1213.910, -50.096, 200.000},
        {"����������", -947.980, -304.320, -1.1, -319.676, 327.071, 200.000},
        {"�������� �����", -1820.640, -2643.680, -8.0, -1226.780, -1771.660, 200.000},
        {"���-�-������", -1166.970, -2641.190, 0.000, -321.744, -1856.030, 200.000},
        {"���� �������", -2994.490, -2189.910, -47.917, -2178.690, -1115.580, 576.083},
        {"������ ������", -1213.910, 596.349, -242.990, -480.539, 1659.680, 900.000},
        {"����� �����", -1213.910, -2892.970, -242.990, 44.615, -768.027, 900.000},
        {"��������", -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000},
        {"��������� �����", -480.539, 596.349, -242.990, 869.461, 2993.870, 900.000},
        {"������ ������", -2997.470, 1659.680, -242.990, -480.539, 2993.870, 900.000},
        {"���-������", -2997.470, -1115.580, -242.990, -1213.910, 1659.680, 900.000},
        {"���-��������", 869.461, 596.349, -242.990, 2997.060, 2993.870, 900.000},
        {"�������� �����", -1213.910, -768.027, -242.990, 2997.060, 596.349, 900.000},
        {"���-������", 44.615, -2892.970, -242.990, 2997.060, -768.027, 900.000}}
	local st = {}
	if buffer.sstr.v == false then
		st = streets
	else
		st = streets2
	end
    for i, v in ipairs(st) do
        if (x >= v[2]) and (y >= v[3]) and (z >= v[4]) and (x <= v[5]) and (y <= v[6]) and (z <= v[7]) then
            return v[1]
        end
    end
    if buffer.sstr.v == false then return "Unknown" else return "����������" end
end

function calculateSquare(x,y,z)
	x,y,z = getCharCoordinates(PLAYER_PED)
	local SquareList = {"�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�", "�"}
	if y < 3000 and y > -3000 and x < 3000 and x > -3000 then
		Square = SquareList[math.ceil((y * - 1 + 3000) / 250)] .. "-" .. math.ceil((x + 3000) / 250)
	end
	return Square
end

function calculateHospital()
	if isCharInArea3d(PLAYER_PED, 270, 30, 1495, 230, -20, 1510) then return true else return false end
end

function calculateCity(LANG)	
	local city_ru = {
		{"���-������", 2930, -2740, 0, 50, -890, 250},
		{"���-������", -1344, -1065, 250, -2981, 1487, 0},
		{"���-��������", 842, 2947, 250, 2970, 570, 0}}
	local city_en = {
		{"Los Santos", 2930, -2740, 0, 50, -890, 250},
		{"San Fierro", -1344, -1065, 250, -2981, 1487, 0},
		{"Las Venturas", 842, 2947, 250, 2970, 570, 0}}
	if LANG == 1 then
		local ct = {}
		if buffer.sstr.v == false then
			 ct = city_en 
		else 
			ct = city_ru
		end
		for i, v in ipairs(ct) do
			if isCharInArea3d(PLAYER_PED, v[2], v[3], v[4], v[5], v[6], v[7]) then 
				return v[1]
			end
		end
		if buffer.sstr.v == false then return "Suburb" else return "��������" end
	end
	if LANG == 2 then
		for i, v in ipairs(city_ru) do
			if isCharInArea3d(PLAYER_PED, v[2], v[3], v[4], v[5], v[6], v[7]) then 
				return v[1]
			end
		end
		return "��������"
	end
end

function calculatePost()
	local medicpost = {
		{"������ ��", 1292, 1718, 13, 1045, -1843, 30},
		{"�����", 1394, -1868, 13, 1564, -1738, 30},
		{"����� 0", 592, -1288, 0, -212, -1500, 30},
		{"���������", -2013, -76, 30, -2095, -280, 50},
		{"������ ��", -2001, 218, 10, -1923, 72, 50},
		{"�������� ��������", -1997, 536, 30, -1907, 598, 50},
		{"��������� �����", -2009, -196, 30, -2201, -280, 50},
		{"������", 2158, 2203, 0, 2363, 2027, 50},
		{"������ ��", 2859, 1382, 0, 2758, 1224, 50},
		{"����� 1", -155, -42, -15, -55, 58, 30}, 
		{"����� 2", -1211, -939, 100, -990, -1267, 150},
		{"����� 3", -55,  14, -15, 45, 114, 30},
		{"����� 4", 1882, 121, -5, 1982, 221, 60}}
	for i, v in ipairs(medicpost) do
		if isCharInArea3d(PLAYER_PED, v[2], v[3], v[4], v[5], v[6], v[7]) then
			return v[1]
		end
	end
	return false
end

------------------------------------------------- ���� --------------------------------------------------

function main_style()

    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 14
    style.ChildWindowRounding = 2
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    colors[clr.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00);
    colors[clr.TextDisabled]           = ImVec4(0.29, 0.29, 0.29, 1.00);
    colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00);
    colors[clr.ChildWindowBg]          = ImVec4(0.10, 0.10, 0.10, 1.00);
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94);
    colors[clr.Border]                 = ImVec4(0.16, 0.16, 0.16, 1.00);
    colors[clr.BorderShadow]           = ImVec4(1.00, 1.00, 1.00, 0.00);
    colors[clr.FrameBg]                = ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[clr.FrameBgHovered]         = ImVec4(0.18, 0.18, 0.18, 1.00);
    colors[clr.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00);
    colors[clr.TitleBg]                = ImVec4(0.14, 0.14, 0.14, 0.81);
    colors[clr.TitleBgActive]          = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51);
    colors[clr.MenuBarBg]              = ImVec4(0.20, 0.20, 0.20, 1.00);
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39);
    colors[clr.ScrollbarGrab]          = ImVec4(0.36, 0.36, 0.36, 1.00);
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00);
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.24, 0.24, 0.24, 1.00);
	colors[clr.Separator]              = ImVec4(0.16, 0.16, 0.16, 1.00);
    colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.CheckMark]              = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrab]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrabActive]       = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.Button]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.ButtonHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ButtonActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.Header]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.HeaderHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.HeaderActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.ResizeGrip]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.ResizeGripHovered]      = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.19, 0.19, 1.00);
    colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16);
    colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39);
    colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00);
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[clr.PlotHistogram]          = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.18, 0.18, 1.00);
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.32, 0.32, 1.00);
    colors[clr.ModalWindowDarkening]   = ImVec4(0.26, 0.26, 0.26, 0.60);
end
main_style()
