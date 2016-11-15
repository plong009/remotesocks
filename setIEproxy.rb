require "fiddle"
require 'fiddle/import'

include Fiddle::CParser
include Fiddle::Importer


module SystemProxy

	INTERNET_PER_CONN_FLAGS = 1
	INTERNET_PER_CONN_PROXY_SERVER = 2
	INTERNET_PER_CONN_PROXY_BYPASS = 3
	INTERNET_PER_CONN_AUTOCONFIG_URL = 4
	INTERNET_PER_CONN_AUTODISCOVERY_FLAGS = 5
	INTERNET_PER_CONN_AUTOCONFIG_SECONDARY_URL = 6
	INTERNET_PER_CONN_AUTOCONFIG_RELOAD_DELAY_MINS = 7
	INTERNET_PER_CONN_AUTOCONFIG_LAST_DETECT_TIME = 8
	INTERNET_PER_CONN_AUTOCONFIG_LAST_DETECT_URL = 9
	INTERNET_PER_CONN_FLAGS_UI = 10

	INTERNET_OPTION_PER_CONNECTION_OPTION = 75
	INTERNET_OPTION_SETTINGS_CHANGED = 39
	INTERNET_OPTION_REFRESH = 37
	INTERNET_OPTION_PROXY_SETTINGS_CHANGED = 95

	PROXY_TYPE_DIRECT = 0x00000001
	PROXY_TYPE_PROXY = 0x00000002
	PROXY_TYPE_AUTO_PROXY_URL = 0x00000004
	PROXY_TYPE_AUTO_DETECT = 0x00000008


	def SystemProxy.setIEproxy(mode, url)
		#BOOL InternetSetOption(
		#  _In_ HINTERNET hInternet,
		#  _In_ DWORD     dwOption,
		#  _In_ LPVOID    lpBuffer,
		#  _In_ DWORD     dwBufferLength
		#);
		wininet = Fiddle.dlopen "wininet.dll"
		internetSetOption = Fiddle::Function.new(wininet['InternetSetOption'],[Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG], Fiddle::TYPE_LONG);

		#typedef struct {
		#  DWORD                      dwSize;
		#  LPTSTR                     pszConnection;
		#  DWORD                      dwOptionCount;
		#  DWORD                      dwOptionError;
		#  LPINTERNET_PER_CONN_OPTION pOptions;
		#} INTERNET_PER_CONN_OPTION_LIST, *LPINTERNET_PER_CONN_OPTION_LIST;
		optionList = struct [	"unsigned long dwSize",
								"char*         pszConnection",
								"unsigned long dwOptionCount",
								"unsigned long dwOptionError",
								"void*         pOptions"] 

		#typedef struct {
		#  DWORD dwOption;
		#  union {
		#    DWORD    dwValue;
		#    LPTSTR   pszValue;
		#    FILETIME ftValue;
		#  } Value;
		#} INTERNET_PER_CONN_OPTION, *LPINTERNET_PER_CONN_OPTION;
		dWOption  = struct ["unsigned long dwOption",
							"unsigned long dwValue0", #to compliant the alignment issue on 64bit or 32bit  platform
							"unsigned long dwValue1",
							"unsigned long dwValue2"]
		pSZOption = struct ["unsigned long dwOption",
							"char*         pszValue",
							"unsigned long padding0",
							"unsigned long padding1"]

		list   = optionList.malloc
		direct = dWOption.malloc
		pac0   = dWOption.malloc
		pac1   = pSZOption.malloc
		glb0   = dWOption.malloc
		glb1   = pSZOption.malloc
		glb2   = pSZOption.malloc

		list.dwSize = sizeof(list);
		list.pszConnection = 0; 
		list.dwOptionCount = 1;
		list.dwOptionError = 0;

		direct.dwOption = INTERNET_PER_CONN_FLAGS_UI
		direct.dwValue0 = direct.dwValue1 = direct.dwValue2 = PROXY_TYPE_AUTO_DETECT|PROXY_TYPE_DIRECT
		
		pac0.dwOption = INTERNET_PER_CONN_FLAGS_UI
		pac0.dwValue0  = pac0.dwValue1  = pac0.dwValue2  = PROXY_TYPE_AUTO_PROXY_URL
		pac1.dwOption = INTERNET_PER_CONN_AUTOCONFIG_URL
		pac1.pszValue = url
		
		glb0.dwOption = INTERNET_PER_CONN_FLAGS_UI
		glb0.dwValue0  = glb0.dwValue1  = glb0.dwValue2  = PROXY_TYPE_PROXY|PROXY_TYPE_DIRECT
		glb1.dwOption = INTERNET_PER_CONN_PROXY_SERVER
		glb1.pszValue = url
		glb2.dwOption = INTERNET_PER_CONN_PROXY_BYPASS
		glb2.pszValue = "<local>"

		if mode =~ /direct/i
			list.pOptions = direct
			internetSetOption.call(0, INTERNET_OPTION_PER_CONNECTION_OPTION, list, sizeof(list))
		elsif mode =~ /pac/i
			list.pOptions = pac0
			internetSetOption.call(0, INTERNET_OPTION_PER_CONNECTION_OPTION, list, sizeof(list))
			list.pOptions = pac1
			internetSetOption.call(0, INTERNET_OPTION_PER_CONNECTION_OPTION, list, sizeof(list))
		else
			list.pOptions = glb0
			internetSetOption.call(0, INTERNET_OPTION_PER_CONNECTION_OPTION, list, sizeof(list))
			list.pOptions = glb1
			internetSetOption.call(0, INTERNET_OPTION_PER_CONNECTION_OPTION, list, sizeof(list))
			list.pOptions = glb2
			internetSetOption.call(0, INTERNET_OPTION_PER_CONNECTION_OPTION, list, sizeof(list))
		end

		internetSetOption.call(0, INTERNET_OPTION_PROXY_SETTINGS_CHANGED, "", 0)
		internetSetOption.call(0, INTERNET_OPTION_REFRESH, "", 0)
		
		wininet.close
		Fiddle.free(list.to_i)
		Fiddle.free(direct.to_i)
		Fiddle.free(pac0.to_i)
		Fiddle.free(pac1.to_i)
		Fiddle.free(glb0.to_i)
		Fiddle.free(glb1.to_i)
		Fiddle.free(glb2.to_i)
	end

	
end
